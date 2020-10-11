-- update additional columns
UPDATE chair SET
  price_id = CASE
    WHEN price < 3000 THEN 0
    WHEN 3000 <= price AND price < 6000 THEN 1
    WHEN 6000 <= price AND price < 9000 THEN 2
    WHEN 9000 <= price AND price < 12000 THEN 3
    WHEN 12000 <= price AND price < 15000 THEN 4
    ELSE 5
  END,
  height_id = CASE
    WHEN height < 80 THEN 0
    WHEN 80 <= height AND height < 110 THEN 1
    WHEN 110 <= height AND height < 150 THEN 2
    ELSE 3
  END,
  width_id = CASE
    WHEN width < 80 THEN 0
    WHEN 80 <= width AND width < 110 THEN 1
    WHEN 110 <= width AND width < 150 THEN 2
    ELSE 3
  END,
  depth_id = CASE
    WHEN depth < 80 THEN 0
    WHEN 80 <= depth AND depth < 110 THEN 1
    WHEN 110 <= depth AND depth < 150 THEN 2
    ELSE 3
  END,
  color_id = CASE
    WHEN color = '黒' THEN 0
    WHEN color = '白' THEN 1
    WHEN color = '赤' THEN 2
    WHEN color = '青' THEN 3
    WHEN color = '緑' THEN 4
    WHEN color = '黃' THEN 5
    WHEN color = '紫' THEN 6
    WHEN color = 'ピンク' THEN 7
    WHEN color = 'オレンジ' THEN 8
    WHEN color = '水色' THEN 9
    WHEN color = 'ネイビー' THEN 10
    ELSE 11
  END,
  kind_id = CASE
    WHEN kind = 'ゲーミングチェア' THEN 0
    WHEN kind = '座椅子' THEN 1
    WHEN kind = 'エルゴノミクス' THEN 2
    ELSE 3
  END;

INSERT INTO chair_counts
  SELECT
    price_id,
    height_id,
    width_id,
    depth_id,
    kind_id,
    COUNT(*)
  FROM
    chair
  GROUP BY
    price_id,
    height_id,
    width_id,
    depth_id,
    kind_id;

-- indices for ORDER BY
CREATE INDEX ON chair USING btree (price ASC, id ASC);
CREATE INDEX ON chair USING btree (popularity DESC, id ASC);

-- indices for WHERE or JOIN
CREATE INDEX ON chair USING btree (price_id, height_id, width_id);
CREATE INDEX ON chair USING btree (color_id, depth_id, kind_id);
