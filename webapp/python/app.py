from os import getenv
import json
import subprocess
from io import TextIOWrapper

import flask
from werkzeug.exceptions import BadRequest, NotFound
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool

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

pg_connection_env = {
    "host": getenv("PGHOST", "127.0.0.1"),
    "port": getenv("PGPORT", 5432),
    "user": getenv("PGUSER", "isucon"),
    "password": getenv("PGPASSWORD", "isucon"),
    "dbname": getenv("PGDATABASE", "isuumo"),
}

conn_pool = SimpleConnectionPool(
    minconn=5,
    maxconn=10,
    **pg_connection_env,
    cursor_factory=RealDictCursor,
)


def select_all(query, *args):
    conn = conn_pool.getconn()
    conn.set_session(autocommit=True)
    try:
        cur = conn.cursor()
        cur.execute(query, *args)
        rows = cur.fetchall()
        return rows
    finally:
        conn_pool.putconn(conn)


def select_one(query, *args, **kwargs):
    conn = conn_pool.getconn()
    conn.set_session(autocommit=True)
    try:
        cur = conn.cursor()
        cur.execute(query, *args)
        row = cur.fetchone()
        return row
    finally:
        conn_pool.putconn(conn)


def camelize_key(estate):
    estate = dict(estate)
    estate["doorHeight"] = estate.pop("door_height")
    estate["doorWidth"] = estate.pop("door_width")
    return estate


@app.route("/initialize", methods=["POST"])
def post_initialize():
    subprocess.run(
        "bash /home/isucon/isuumo/webapp/psql/init.sh", shell=True, check=True
    )
    return {"language": "python"}


@app.route("/api/estate/low_priced", methods=["GET"])
def get_estate_low_priced():
    estates = select_all(
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
    return {"estates": [camelize_key(estate) for estate in estates]}


@app.route("/api/chair/low_priced", methods=["GET"])
def get_chair_low_priced():
    chairs = select_all(
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
    return {"chairs": [dict(chair) for chair in chairs]}


@app.route("/api/chair/search", methods=["GET"])
def get_chair_search():
    args = flask.request.args

    try:
        page = int(args.get("page"))
    except (TypeError, ValueError):
        raise BadRequest("Invalid format page parameter")

    try:
        per_page = int(args.get("perPage"))
    except (TypeError, ValueError):
        raise BadRequest("Invalid format perPage parameter")

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

    search_condition = "\n  AND ".join(conditions)

    query = f"""
SELECT
  COUNT(*) as count
FROM
  chair
WHERE
  {search_condition}
    """
    count = select_one(query, params)["count"]

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
    chairs = select_all(query, params)

    return {"count": count, "chairs": [dict(chair) for chair in chairs]}


@app.route("/api/chair/search/condition", methods=["GET"])
def get_chair_search_condition():
    return chair_search_condition


@app.route("/api/chair/<int:chair_id>", methods=["GET"])
def get_chair(chair_id):
    chair = select_one(
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
    conn = conn_pool.getconn()
    conn.set_session(autocommit=True)
    try:
        cur = conn.cursor()
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
        return {"ok": True}
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn_pool.putconn(conn)


@app.route("/api/estate/search", methods=["GET"])
def get_estate_search():
    args = flask.request.args

    try:
        page = int(args.get("page"))
    except (TypeError, ValueError):
        raise BadRequest("Invalid format page parameter")

    try:
        per_page = int(args.get("perPage"))
    except (TypeError, ValueError):
        raise BadRequest("Invalid format perPage parameter")

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

    search_condition = "\n  AND ".join(conditions)

    query = f"""
SELECT
  COUNT(*) as count
FROM
  estate
WHERE
  {search_condition}
    """
    count = select_one(query, params)["count"]

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
    estates = select_all(query, params)

    return {"count": count, "estates": [camelize_key(estate) for estate in estates]}


@app.route("/api/estate/search/condition", methods=["GET"])
def get_estate_search_condition():
    return estate_search_condition


@app.route("/api/estate/req_doc/<int:estate_id>", methods=["POST"])
def post_estate_req_doc(estate_id):
    estate = select_one(
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
    estates = select_all(
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

    results = {
        "estates": [camelize_key(estate) for estate in estates],
        "count": len(estates),
    }
    return results


@app.route("/api/estate/<int:estate_id>", methods=["GET"])
def get_estate(estate_id):
    estate = select_one(
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
    return camelize_key(estate)


@app.route("/api/recommended_estate/<int:chair_id>", methods=["GET"])
def get_recommended_estate(chair_id):
    estates = select_all(
        f"""
SELECT
  e.id,
  e.name,
  e.description,
  e.thumbnail,
  e.address,
  e.latitude,
  e.longitude,
  e.rent,
  e.door_height,
  e.door_width,
  e.features,
  e.popularity
FROM
  estate AS e,
  chair AS c
WHERE
  c.id = {chair_id}
  AND (
    (e.door_width >= c.width AND e.door_height >= c.height)
    OR (e.door_width >= c.width AND e.door_height >= c.depth)
    OR (e.door_width >= c.height AND e.door_height >= c.width)
    OR (e.door_width >= c.height AND e.door_height >= c.depth)
    OR (e.door_width >= c.depth AND e.door_height >= c.width)
    OR (e.door_width >= c.depth AND e.door_height >= c.height)
  )
ORDER BY
  popularity DESC,
  id ASC
LIMIT
  {LIMIT}
        """
    )
    if len(estates) == 0:
        raise BadRequest(
            f"Invalid format searchRecommendedEstateWithChair id : {chair_id}"
        )
    return {"estates": [camelize_key(estate) for estate in estates]}


@app.route("/api/chair", methods=["POST"])
def post_chair():
    if "chairs" not in flask.request.files:
        raise BadRequest()

    csv_io = TextIOWrapper(flask.request.files["chairs"], encoding="utf-8")
    conn = conn_pool.getconn()
    conn.set_session(autocommit=True)
    try:
        cur = conn.cursor()
        cur.copy_expert(
            """
COPY
  chair
FROM
  STDIN
WITH (
  FORMAT CSV,
  DELIMITER ',',
  FORCE_NOT_NULL(features)
)
            """,
            csv_io,
        )
        return {"ok": True}, 201
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn_pool.putconn(conn)


@app.route("/api/estate", methods=["POST"])
def post_estate():
    if "estates" not in flask.request.files:
        raise BadRequest()

    csv_io = TextIOWrapper(flask.request.files["estates"], encoding="utf-8")
    conn = conn_pool.getconn()
    conn.set_session(autocommit=True)
    try:
        cur = conn.cursor()
        cur.copy_expert(
            """
COPY
  estate (
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
  )
FROM
  STDIN
WITH (
  FORMAT CSV,
  DELIMITER ',',
  FORCE_NOT_NULL(features)
)
            """,
            csv_io,
        )
        return {"ok": True}, 201
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn_pool.putconn(conn)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=getenv("SERVER_PORT", 1323), debug=True, threaded=True)
