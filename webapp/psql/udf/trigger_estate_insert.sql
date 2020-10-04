DROP TRIGGER IF EXISTS estate_insert_trigger ON estate;
CREATE TRIGGER estate_insert_trigger
  AFTER INSERT
  ON estate
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE FUNCTION update_estates();
