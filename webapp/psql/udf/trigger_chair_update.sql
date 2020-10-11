DROP TRIGGER IF EXISTS chair_update_trigger ON chair;
CREATE TRIGGER chair_update_trigger
  AFTER UPDATE
  ON chair
  REFERENCING NEW TABLE AS new
  FOR EACH ROW
  WHEN (new.stock = 0)
  EXECUTE FUNCTION reduce_chair_counts();
