DROP FUNCTION IF EXISTS analyze_chairs;
CREATE FUNCTION analyze_chairs ()
RETURNS TRIGGER
VOLATILE AS $$
DECLARE
BEGIN
  IF (SELECT MAX(id) = 39000 FROM chair) THEN
    ANALYZE chair (height, width, depth, kind, color);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
