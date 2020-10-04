DROP FUNCTION IF EXISTS update_estates;
CREATE OR REPLACE FUNCTION update_estates ()
RETURNS TRIGGER
VOLATILE AS $$
DECLARE
BEGIN
  UPDATE NEW SET
    NEW.geom_coords = ST_MakePoint(NEW.longitude, NEW.latitude);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
