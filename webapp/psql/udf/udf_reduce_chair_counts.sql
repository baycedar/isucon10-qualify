DROP FUNCTION IF EXISTS reduce_chair_counts;
CREATE FUNCTION reduce_chair_counts ()
RETURNS TRIGGER
VOLATILE AS $$
DECLARE
BEGIN
  UPDATE chair_counts AS c SET
    counts = c.counts - 1
    FROM new AS n
    WHERE
      c.price_id = n.price_id
      AND c.height_id = n.height_id
      AND c.width_id = n.width_id
      AND c.depth_id = n.depth_id
      AND c.kind_id = n.kind_id
  ;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
