from os import getenv
import json
import subprocess
from io import StringIO
import csv

import flask
from werkzeug.exceptions import BadRequest, NotFound
from sqlalchemy.pool import QueuePool
from humps import camelize
import psycopg2
from psycopg2.extras import RealDictCursor, execute_values

LIMIT = 20
NAZOTTE_LIMIT = 50

chair_search_condition = json.load(
    open(
        # VS Code's test does not work with relative paths
        "../fixture/chair_condition.json",
        # "/home/sugiura/workspace/isucon/isucon10-qual/webapp/fixture/chair_condition.json",
        "r",
    )
)
estate_search_condition = json.load(
    open(
        # VS Code's test does not work with relative paths
        "../fixture/estate_condition.json",
        # "/home/sugiura/workspace/isucon/isucon10-qual/webapp/fixture/estate_condition.json",
        "r",
    )
)

app = flask.Flask(__name__)

estate_connection_env = {
    "host": getenv("PG_ESTATE_HOST", "127.0.0.1"),
    "port": getenv("PGPORT", 5432),
    "user": getenv("PGUSER", "isucon"),
    "password": getenv("PGPASSWORD", "isucon"),
    "dbname": getenv("PGDATABASE", "isuumo"),
}

chair_connection_env = {
    "host": getenv("PG_CHAIR_HOST", "127.0.0.1"),
    "port": getenv("PGPORT", 5432),
    "user": getenv("PGUSER", "isucon"),
    "password": getenv("PGPASSWORD", "isucon"),
    "dbname": getenv("PGDATABASE", "isuumo"),
}

estate_pool = QueuePool(
    lambda: psycopg2.connect(**estate_connection_env, cursor_factory=RealDictCursor),
    pool_size=10,
)
chair_pool = QueuePool(
    lambda: psycopg2.connect(**chair_connection_env, cursor_factory=RealDictCursor),
    pool_size=10,
)


def select_estates(query, *args):
    cnx = estate_pool.connect()
    try:
        cur = cnx.cursor()
        cur.execute(query, *args)
        rows = cur.fetchall()
        return rows
    finally:
        cnx.close()


def select_estate(*args, **kwargs):
    rows = select_estates(*args, **kwargs)
    return rows[0] if len(rows) > 0 else None


def select_chairs(query, *args):
    cnx = chair_pool.connect()
    try:
        cur = cnx.cursor()
        cur.execute(query, *args)
        rows = cur.fetchall()
        return rows
    finally:
        cnx.close()


def select_chair(*args, **kwargs):
    rows = select_chairs(*args, **kwargs)
    return rows[0] if len(rows) > 0 else None


@app.route("/initialize", methods=["POST"])
def post_initialize():
    subprocess.run(
        "bash /home/isucon/isuumo/webapp/psql/db/init.sh", shell=True, check=True
    )
    return {"language": "python"}


@app.route("/api/estate/low_priced", methods=["GET"])
def get_estate_low_priced():
    rows = select_estates(
        f"""
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
ORDER BY
  rent ASC,
  id ASC
LIMIT
  {LIMIT}
        """,
    )
    return {"estates": camelize(rows)}


@app.route("/api/chair/low_priced", methods=["GET"])
def get_chair_low_priced():
    rows = select_chairs(
        f"""
SELECT
  id,
  name,
  description,
  thumbnail,
  price,
  height,
  width,
  depth,
  color,
  features,
  kind,
  popularity,
  stock
FROM
  chair
WHERE
  stock > 0
ORDER BY
  price ASC,
  id ASC
LIMIT
  {LIMIT}
        """,
    )
    return {"chairs": [dict(row) for row in rows]}


@app.route("/api/chair/search", methods=["GET"])
def get_chair_search():
    args = flask.request.args

    conditions = []
    params = []

    if args.get("priceRangeId"):
        for _range in chair_search_condition["price"]["ranges"]:
            if _range["id"] == int(args.get("priceRangeId")):
                price = _range
                break
        else:
            raise BadRequest("priceRangeID invalid")
        if price["min"] != -1:
            conditions.append("price >= %s")
            params.append(price["min"])
        if price["max"] != -1:
            conditions.append("price < %s")
            params.append(price["max"])

    if args.get("heightRangeId"):
        for _range in chair_search_condition["height"]["ranges"]:
            if _range["id"] == int(args.get("heightRangeId")):
                height = _range
                break
        else:
            raise BadRequest("heightRangeId invalid")
        if height["min"] != -1:
            conditions.append("height >= %s")
            params.append(height["min"])
        if height["max"] != -1:
            conditions.append("height < %s")
            params.append(height["max"])

    if args.get("widthRangeId"):
        for _range in chair_search_condition["width"]["ranges"]:
            if _range["id"] == int(args.get("widthRangeId")):
                width = _range
                break
        else:
            raise BadRequest("widthRangeId invalid")
        if width["min"] != -1:
            conditions.append("width >= %s")
            params.append(width["min"])
        if width["max"] != -1:
            conditions.append("width < %s")
            params.append(width["max"])

    if args.get("depthRangeId"):
        for _range in chair_search_condition["depth"]["ranges"]:
            if _range["id"] == int(args.get("depthRangeId")):
                depth = _range
                break
        else:
            raise BadRequest("depthRangeId invalid")
        if depth["min"] != -1:
            conditions.append("depth >= %s")
            params.append(depth["min"])
        if depth["max"] != -1:
            conditions.append("depth < %s")
            params.append(depth["max"])

    if args.get("kind"):
        conditions.append("kind = %s")
        params.append(args.get("kind"))

    if args.get("color"):
        conditions.append("color = %s")
        params.append(args.get("color"))

    if args.get("features"):
        for feature_condition in args.get("features").split(","):
            conditions.append(f"features LIKE '%%{feature_condition}%%'")

    if len(conditions) == 0:
        raise BadRequest("Search condition not found")

    conditions.append("stock > 0")

    try:
        page = int(args.get("page"))
    except (TypeError, ValueError):
        raise BadRequest("Invalid format page parameter")

    try:
        per_page = int(args.get("perPage"))
    except (TypeError, ValueError):
        raise BadRequest("Invalid format perPage parameter")

    search_condition = " AND ".join(conditions)

    query = f"""
SELECT
  COUNT(*) as count
FROM
  chair
WHERE
  {search_condition}
    """
    count = select_chair(query, params)["count"]

    query = f"""
SELECT
  id,
  name,
  description,
  thumbnail,
  price,
  height,
  width,
  depth,
  color,
  features,
  kind,
  popularity,
  stock
FROM
  chair
WHERE
  {search_condition}
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  {per_page}
OFFSET
  {per_page * page}
    """
    chairs = select_chairs(query, params)

    return {"count": count, "chairs": [dict(chair) for chair in chairs]}


@app.route("/api/chair/search/condition", methods=["GET"])
def get_chair_search_condition():
    return chair_search_condition


@app.route("/api/chair/<int:chair_id>", methods=["GET"])
def get_chair(chair_id):
    chair = select_chair(
        f"""
SELECT
  id,
  name,
  description,
  thumbnail,
  price,
  height,
  width,
  depth,
  color,
  features,
  kind,
  popularity,
  stock
FROM
  chair
WHERE
  id = {chair_id}
  AND stock > 0
        """,
    )
    if chair is None:
        raise NotFound()
    return dict(chair)


@app.route("/api/chair/buy/<int:chair_id>", methods=["POST"])
def post_chair_buy(chair_id):
    cnx = chair_pool.connect()
    try:
        cur = cnx.cursor()
        cur.execute(
            f"""
UPDATE
  chair
SET
  stock = stock - 1
WHERE
  id = {chair_id}
  AND stock > 0
RETURNING
  id
            """,
        )
        result = cur.fetchone()
        if result is None:
            raise NotFound()
        cnx.commit()
        return {"ok": True}
    except Exception as e:
        cnx.rollback()
        raise e
    finally:
        cnx.close()


@app.route("/api/estate/search", methods=["GET"])
def get_estate_search():
    args = flask.request.args

    conditions = []
    params = []

    if args.get("doorHeightRangeId"):
        for _range in estate_search_condition["doorHeight"]["ranges"]:
            if _range["id"] == int(args.get("doorHeightRangeId")):
                door_height = _range
                break
        else:
            raise BadRequest("doorHeightRangeId invalid")
        if door_height["min"] != -1:
            conditions.append("door_height >= %s")
            params.append(door_height["min"])
        if door_height["max"] != -1:
            conditions.append("door_height < %s")
            params.append(door_height["max"])

    if args.get("doorWidthRangeId"):
        for _range in estate_search_condition["doorWidth"]["ranges"]:
            if _range["id"] == int(args.get("doorWidthRangeId")):
                door_width = _range
                break
        else:
            raise BadRequest("doorWidthRangeId invalid")
        if door_width["min"] != -1:
            conditions.append("door_width >= %s")
            params.append(door_width["min"])
        if door_width["max"] != -1:
            conditions.append("door_width < %s")
            params.append(door_width["max"])

    if args.get("rentRangeId"):
        for _range in estate_search_condition["rent"]["ranges"]:
            if _range["id"] == int(args.get("rentRangeId")):
                rent = _range
                break
        else:
            raise BadRequest("rentRangeId invalid")
        if rent["min"] != -1:
            conditions.append("rent >= %s")
            params.append(rent["min"])
        if rent["max"] != -1:
            conditions.append("rent < %s")
            params.append(rent["max"])

    if args.get("features"):
        for feature_condition in args.get("features").split(","):
            conditions.append(f"features LIKE '%%{feature_condition}%%'")

    if len(conditions) == 0:
        raise BadRequest("Search condition not found")

    try:
        page = int(args.get("page"))
    except (TypeError, ValueError):
        raise BadRequest("Invalid format page parameter")

    try:
        per_page = int(args.get("perPage"))
    except (TypeError, ValueError):
        raise BadRequest("Invalid format perPage parameter")

    search_condition = " AND ".join(conditions)

    query = f"""
SELECT
  COUNT(*) as count
FROM
  estate
WHERE
  {search_condition}
    """
    count = select_estate(query, params)["count"]

    query = f"""
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
WHERE
  {search_condition}
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  {per_page}
OFFSET
  {per_page * page}
    """
    chairs = select_estates(query, params)

    return {"count": count, "estates": camelize(chairs)}


@app.route("/api/estate/search/condition", methods=["GET"])
def get_estate_search_condition():
    return estate_search_condition


@app.route("/api/estate/req_doc/<int:estate_id>", methods=["POST"])
def post_estate_req_doc(estate_id):
    estate = select_estate(
        f"""
SELECT
  id
FROM
  estate
WHERE
  id = {estate_id}
        """,
    )
    if estate is None:
        raise NotFound()
    return {"ok": True}


@app.route("/api/estate/nazotte", methods=["POST"])
def post_estate_nazotte():
    if "coordinates" not in flask.request.json:
        raise BadRequest()
    coordinates = flask.request.json["coordinates"]
    if len(coordinates) == 0:
        raise BadRequest()
    polygon_text = f"""
POLYGON((
  {','.join(['{} {}'.format(c['longitude'], c['latitude']) for c in coordinates])}
))
    """
    estates = select_estates(
        f"""
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
WHERE
  ST_Contains(
    ST_PolygonFromText('{polygon_text}'),
    geom_coords
  )
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  {NAZOTTE_LIMIT}
        """
    )

    results = {"estates": [camelize(estate) for estate in estates]}
    results["count"] = len(results["estates"])
    return results


@app.route("/api/estate/<int:estate_id>", methods=["GET"])
def get_estate(estate_id):
    estate = select_estate(
        f"""
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
WHERE
  id = {estate_id}
        """,
    )
    if estate is None:
        raise NotFound()
    return camelize(estate)


@app.route("/api/recommended_estate/<int:chair_id>", methods=["GET"])
def get_recommended_estate(chair_id):
    query = f"""
SELECT
  width,
  height,
  depth
FROM
  chair
WHERE
  id = {chair_id}
    """
    chair = select_chair(query)
    if chair is None:
        raise BadRequest(
            f"Invalid format searchRecommendedEstateWithChair id : {chair_id}"
        )
    c_width = chair["width"]
    c_height = chair["height"]
    c_depth = chair["depth"]

    query = f"""
SELECT
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity
FROM
  estate
WHERE
  (door_width >= {c_width} AND door_height >= {c_height})
  OR (door_width >= {c_width} AND door_height >= {c_depth})
  OR (door_width >= {c_height} AND door_height >= {c_width})
  OR (door_width >= {c_height} AND door_height >= {c_depth})
  OR (door_width >= {c_depth} AND door_height >= {c_width})
  OR (door_width >= {c_depth} AND door_height >= {c_height})
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  {LIMIT}
    """
    estates = select_estates(query)
    return {"estates": camelize(estates)}


@app.route("/api/chair", methods=["POST"])
def post_chair():
    if "chairs" not in flask.request.files:
        raise BadRequest()
    records = csv.reader(StringIO(flask.request.files["chairs"].read().decode()))
    records = [tuple(record) for record in records]
    cnx = chair_pool.connect()
    try:
        cur = cnx.cursor()
        query = """
INSERT INTO chair (
  id,
  name,
  description,
  thumbnail,
  price,
  height,
  width,
  depth,
  color,
  features,
  kind,
  popularity,
  stock
) VALUES
  %s
        """
        execute_values(cur, query, records)
        cnx.commit()
        return {"ok": True}, 201
    except Exception as e:
        cnx.rollback()
        raise e
    finally:
        cnx.close()


@app.route("/api/estate", methods=["POST"])
def post_estate():
    if "estates" not in flask.request.files:
        raise BadRequest()
    records = csv.reader(StringIO(flask.request.files["estates"].read().decode()))
    records = [rec + [f"Point({rec[6]} {rec[5]})"] for rec in records]
    records = [tuple(rec) for rec in records]
    cnx = estate_pool.connect()
    try:
        cur = cnx.cursor()
        query = """
INSERT INTO estate (
  id,
  name,
  description,
  thumbnail,
  address,
  latitude,
  longitude,
  rent,
  door_height,
  door_width,
  features,
  popularity,
  geom_coords
) VALUES
  %s
        """
        execute_values(cur, query, records)
        cnx.commit()
        return {"ok": True}, 201
    except Exception as e:
        cnx.rollback()
        raise e
    finally:
        cnx.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=getenv("SERVER_PORT", 1323), debug=True, threaded=True)
