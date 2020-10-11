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

DROP TABLE IF EXISTS chair_counts CASCADE;

CREATE TABLE chair_counts
(
    price_id INTEGER NOT NULL,
    height_id INTEGER NOT NULL,
    width_id INTEGER NOT NULL,
    depth_id INTEGER NOT NULL,
    kind_id INTEGER NOT NULL,
    counts INTEGER NOT NULL
);
