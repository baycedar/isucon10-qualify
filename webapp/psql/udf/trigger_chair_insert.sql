DROP TRIGGER IF EXISTS chair_insert_trigger ON chair;
CREATE TRIGGER chair_insert_trigger
  AFTER INSERT
  ON chair
  FOR EACH STATEMENT
  EXECUTE FUNCTION analyze_chairs();
