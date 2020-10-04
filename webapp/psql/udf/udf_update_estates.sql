DROP FUNCTION IF EXISTS update_estates;
CREATE OR REPLACE FUNCTION update_estates ()
RETURNS TRIGGER
VOLATILE AS $$
DECLARE
BEGIN
  UPDATE estate SET
    geom_coords = ST_MakePoint(longitude, latitude)
  WHERE
    geom_coords = ST_MakePoint(0, 0);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
