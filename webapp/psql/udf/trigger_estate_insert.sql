DROP TRIGGER IF EXISTS estate_insert_trigger ON estate;
CREATE TRIGGER estate_insert_trigger
  AFTER INSERT
  ON estate
  FOR EACH STATEMENT
  EXECUTE FUNCTION analyze_estates();
