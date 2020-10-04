CREATE TRIGGER estate_insert_trigger
  AFTER INSERT
  ON estate
  FOR EACH STATEMENT
  EXECUTE FUNCTION update_estates();
