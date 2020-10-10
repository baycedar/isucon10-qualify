-- update additional columns
UPDATE estate SET
  geom_coords = ST_MakePoint(longitude, latitude),
  rent_id = CASE
    WHEN rent < 50000 THEN 0
    WHEN 50000 <= rent AND rent < 100000 THEN 2
    WHEN 100000 <= rent AND rent < 150000 THEN 3
    ELSE 4
  END,
  door_height_id = CASE
    WHEN door_height < 80 THEN 0
    WHEN 80 <= door_height AND door_height < 110 THEN 2
    WHEN 110 <= door_height AND door_height < 150 THEN 3
    ELSE 4
  END,
  door_width_id = CASE
    WHEN door_width < 80 THEN 0
    WHEN 80 <= door_width AND door_width < 110 THEN 2
    WHEN 110 <= door_width AND door_width < 150 THEN 3
    ELSE 4
  END;

-- indices for ORDER BY
CREATE INDEX ON estate USING btree (rent ASC, id ASC);
CREATE INDEX ON estate USING btree (popularity DESC, id ASC);

-- indices for WHERE or JOIN
CREATE INDEX ON estate USING btree (rent_id, door_height_id, door_width_id);
CREATE INDEX ON estate USING gist (geom_coords);
