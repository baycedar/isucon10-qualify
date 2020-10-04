DROP FUNCTION IF EXISTS update_estates;
CREATE OR REPLACE FUNCTION update_estates ()
RETURNS VOID
STABLE AS $$
DECLARE
BEGIN
  UPDATE estate SET
    geom_coords = ST_MakePoint(longitude, latitude);
  RETURN;
END;
$$ LANGUAGE plpgsql;
