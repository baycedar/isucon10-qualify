-- indices for ORDER BY
CREATE INDEX ON chair USING btree (price ASC, id ASC);
CREATE INDEX ON chair USING btree (popularity DESC, id ASC);

-- indices for WHERE or JOIN
CREATE INDEX ON chair USING btree (height);
CREATE INDEX ON chair USING btree (width);
CREATE INDEX ON chair USING btree (depth);
CREATE INDEX ON chair USING btree (kind);
CREATE INDEX ON chair USING btree (color);
