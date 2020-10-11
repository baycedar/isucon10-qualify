DROP TRIGGER IF EXISTS chair_insert_trigger ON chair;
CREATE TRIGGER chair_insert_trigger
  AFTER INSERT
  ON chair
  REFERENCING NEW TABLE AS new
  FOR EACH STATEMENT
  EXECUTE FUNCTION update_chair_counts();
