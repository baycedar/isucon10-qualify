-- updates geometries
UPDATE estate SET
  geom_coords = ST_MakePoint(longitude, latitude);

-- indices for ORDER BY
CREATE INDEX ON estate USING btree (rent ASC, id ASC);
CREATE INDEX ON chair USING btree (price ASC, id ASC);
CREATE INDEX ON chair USING btree (popularity DESC, id ASC);
CREATE INDEX ON estate USING btree (popularity DESC, id ASC);

-- vacuum and analyze tables
VACUUM ANALYZE estate;
