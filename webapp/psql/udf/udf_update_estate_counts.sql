DROP FUNCTION IF EXISTS update_estate_counts;
CREATE FUNCTION update_estate_counts ()
RETURNS TRIGGER
VOLATILE AS $$
DECLARE
BEGIN
  WITH
    inserted_counts AS (
      SELECT
        rent_id,
        door_height_id,
        door_width_id,
        COUNT(*) AS counts
      FROM
        new
      GROUP BY
        rent_id,
        door_height_id,
        door_width_id
    )
  UPDATE estate_counts AS e SET
    counts = e.counts + i.counts
    FROM inserted_counts AS i
    WHERE
      e.rent_id = i.rent_id
      AND e.door_height_id = i.door_height_id
      AND e.door_width_id = i.door_width_id
  ;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
