CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_prewarm;

DROP TABLE IF EXISTS chair CASCADE;

CREATE TABLE chair
(
    id          INTEGER         NOT NULL PRIMARY KEY,
    name        VARCHAR(64)     NOT NULL,
    description VARCHAR(4096)   NOT NULL,
    thumbnail   VARCHAR(128)    NOT NULL,
    price       INTEGER         NOT NULL,
    height      INTEGER         NOT NULL,
    width       INTEGER         NOT NULL,
    depth       INTEGER         NOT NULL,
    color       VARCHAR(64)     NOT NULL,
    features    VARCHAR(64)     NOT NULL,
    kind        VARCHAR(64)     NOT NULL,
    popularity  INTEGER         NOT NULL,
    stock       INTEGER         NOT NULL,
    price_id INTEGER DEFAULT -1 NOT NULL,
    height_id INTEGER DEFAULT -1 NOT NULL,
    width_id INTEGER DEFAULT -1 NOT NULL,
    depth_id INTEGER DEFAULT -1 NOT NULL,
    color_id INTEGER DEFAULT -1 NOT NULL,
    kind_id INTEGER DEFAULT -1 NOT NULL
);

ALTER TABLE chair
  ALTER COLUMN name SET STATISTICS 0,
  ALTER COLUMN description SET STATISTICS 0,
  ALTER COLUMN thumbnail SET STATISTICS 0,
  ALTER COLUMN height SET STATISTICS 0,
  ALTER COLUMN width SET STATISTICS 0,
  ALTER COLUMN depth SET STATISTICS 0,
  ALTER COLUMN color SET STATISTICS 0,
  ALTER COLUMN kind SET STATISTICS 0;
