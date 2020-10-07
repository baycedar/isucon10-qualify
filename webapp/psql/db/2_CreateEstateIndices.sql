-- update additional columns
UPDATE estate SET geom_coords = ST_MakePoint(longitude, latitude);

-- indices for ORDER BY
CREATE INDEX ON estate USING btree (rent ASC, id ASC);
CREATE INDEX ON estate USING btree (popularity DESC, id ASC);

-- indices for WHERE or JOIN
CREATE INDEX ON estate USING btree (door_height);
CREATE INDEX ON estate USING btree (door_width);
CREATE INDEX ON estate USING gist (geom_coords);
