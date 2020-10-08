DROP FUNCTION IF EXISTS analyze_estates;
CREATE FUNCTION analyze_estates ()
RETURNS TRIGGER
VOLATILE AS $$
DECLARE
BEGIN
  IF (SELECT MAX(id) = 33000 OR MAX(id) = 36000 OR MAX(id) = 39000 FROM estate) THEN
    ANALYZE estate (rent, door_height, door_width);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
