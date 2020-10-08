DROP FUNCTION IF EXISTS analyze_estates;
CREATE FUNCTION analyze_estates ()
RETURNS TRIGGER
VOLATILE AS $$
DECLARE
BEGIN
  ANALYZE estate (rent, door_height, door_width);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
