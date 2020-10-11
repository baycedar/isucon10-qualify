CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_prewarm;

DROP TABLE IF EXISTS estate CASCADE;

CREATE TABLE estate
(
    id          INTEGER             NOT NULL PRIMARY KEY,
    name        VARCHAR(64)         NOT NULL,
    description VARCHAR(4096)       NOT NULL,
    thumbnail   VARCHAR(128)        NOT NULL,
    address     VARCHAR(128)        NOT NULL,
    latitude    DOUBLE PRECISION    NOT NULL,
    longitude   DOUBLE PRECISION    NOT NULL,
    rent        INTEGER             NOT NULL,
    door_height INTEGER             NOT NULL,
    door_width  INTEGER             NOT NULL,
    features    VARCHAR(64)         NOT NULL,
    popularity  INTEGER             NOT NULL,
    geom_coords GEOMETRY DEFAULT ST_MakePoint(0, 0) NOT NULL,
    rent_id INTEGER DEFAULT -1 NOT NULL,
    door_height_id INTEGER DEFAULT -1 NOT NULL,
    door_width_id INTEGER DEFAULT -1 NOT NULL
);

ALTER TABLE estate
  ALTER COLUMN name SET STATISTICS 0,
  ALTER COLUMN description SET STATISTICS 0,
  ALTER COLUMN thumbnail SET STATISTICS 0,
  ALTER COLUMN address SET STATISTICS 0,
  ALTER COLUMN latitude SET STATISTICS 0,
  ALTER COLUMN longitude SET STATISTICS 0,
  ALTER COLUMN door_height SET STATISTICS 0,
  ALTER COLUMN door_width SET STATISTICS 0,
  ALTER COLUMN features SET STATISTICS 0;

DROP TABLE IF EXISTS estate_counts CASCADE;
CREATE TABLE estate_counts
(
    rent_id INTEGER NOT NULL,
    door_height_id INTEGER NOT NULL,
    door_width_id INTEGER NOT NULL,
    counts INTEGER NOT NULL
);
