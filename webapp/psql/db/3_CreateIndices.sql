-- indices for ORDER BY
CREATE INDEX ON estate USING btree (rent ASC, id ASC);
CREATE INDEX ON chair USING btree (price ASC, id ASC);
CREATE INDEX ON chair USING btree (popularity DESC, id ASC);
CREATE INDEX ON estate USING btree (popularity DESC, id ASC);

-- indices for WHERE or JOIN
CREATE INDEX ON chair USING btree (stock);
CREATE INDEX ON chair USING btree (height);
CREATE INDEX ON chair USING btree (width);
CREATE INDEX ON chair USING btree (depth);
CREATE INDEX ON chair USING btree (kind);
CREATE INDEX ON chair USING btree (color);
CREATE INDEX ON estate USING btree (door_height);
CREATE INDEX ON estate USING btree (door_width);
CREATE INDEX ON estate USING btree (latitude);
CREATE INDEX ON estate USING btree (longitude);
