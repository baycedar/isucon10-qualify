DROP FUNCTION IF EXISTS update_chair_counts;
CREATE FUNCTION update_chair_counts ()
RETURNS TRIGGER
VOLATILE AS $$
DECLARE
BEGIN
  WITH
    inserted_counts AS (
      SELECT
        price_id,
        height_id,
        width_id,
        depth_id,
        kind_id,
        COUNT(*) AS counts
      FROM
        new
      GROUP BY
        price_id,
        height_id,
        width_id,
        depth_id,
        kind_id
    )
  UPDATE chair_counts AS c SET
    counts = c.counts + i.counts
    FROM inserted_counts AS i
    WHERE
      c.price_id = i.price_id
      AND c.height_id = i.height_id
      AND c.width_id = i.width_id
      AND c.depth_id = i.depth_id
      AND c.kind_id = i.kind_id
  ;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
