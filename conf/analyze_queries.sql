SELECT 'Order by call counts' AS sort_type;

SELECT
  query,
  calls,
  total_time,
  min_time,
  max_time,
  mean_time,
  stddev_time,
  rows,
  shared_blks_hit,
  shared_blks_read,
  shared_blks_dirtied,
  shared_blks_written,
  local_blks_hit,
  local_blks_read,
  local_blks_dirtied,
  local_blks_written,
  temp_blks_read,
  temp_blks_written
FROM
  pg_stat_statements
WHERE
  NOT query LIKE '%pg_catalog%'
  AND NOT query LIKE '%pg_stat%'
  AND NOT query LIKE 'BEGIN'
  AND NOT query LIKE 'COMMIT'
  AND NOT query LIKE 'ROLLBACK'
  AND NOT query LIKE 'INSERT%' -- ignore bulk inserts
ORDER BY
  calls DESC
LIMIT
  30;

SELECT 'Order by total time' AS sort_type;

SELECT
  query,
  calls,
  total_time,
  min_time,
  max_time,
  mean_time,
  stddev_time,
  rows,
  shared_blks_hit,
  shared_blks_read,
  shared_blks_dirtied,
  shared_blks_written,
  local_blks_hit,
  local_blks_read,
  local_blks_dirtied,
  local_blks_written,
  temp_blks_read,
  temp_blks_written
FROM
  pg_stat_statements
WHERE
  NOT query LIKE '%pg_catalog%'
  AND NOT query LIKE '%pg_stat%'
  AND NOT query LIKE 'BEGIN'
  AND NOT query LIKE 'COMMIT'
  AND NOT query LIKE 'ROLLBACK'
  AND NOT query LIKE 'INSERT%' -- ignore bulk inserts
ORDER BY
  total_time DESC
LIMIT
  30;

SELECT 'Order by mean time' AS sort_type;

SELECT
  query,
  calls,
  total_time,
  min_time,
  max_time,
  mean_time,
  stddev_time,
  rows,
  shared_blks_hit,
  shared_blks_read,
  shared_blks_dirtied,
  shared_blks_written,
  local_blks_hit,
  local_blks_read,
  local_blks_dirtied,
  local_blks_written,
  temp_blks_read,
  temp_blks_written
FROM
  pg_stat_statements
WHERE
  NOT query LIKE '%pg_catalog%'
  AND NOT query LIKE '%pg_stat%'
  AND NOT query LIKE 'BEGIN'
  AND NOT query LIKE 'COMMIT'
  AND NOT query LIKE 'ROLLBACK'
  AND NOT query LIKE 'INSERT%' -- ignore bulk inserts
ORDER BY
  mean_time DESC
LIMIT
  30;

SELECT 'Order by standard deviation' AS sort_type;

SELECT
  query,
  calls,
  total_time,
  min_time,
  max_time,
  mean_time,
  stddev_time,
  rows,
  shared_blks_hit,
  shared_blks_read,
  shared_blks_dirtied,
  shared_blks_written,
  local_blks_hit,
  local_blks_read,
  local_blks_dirtied,
  local_blks_written,
  temp_blks_read,
  temp_blks_written
FROM
  pg_stat_statements
WHERE
  NOT query LIKE '%pg_catalog%'
  AND NOT query LIKE '%pg_stat%'
  AND NOT query LIKE 'BEGIN'
  AND NOT query LIKE 'COMMIT'
  AND NOT query LIKE 'ROLLBACK'
  AND NOT query LIKE 'INSERT%' -- ignore bulk inserts
ORDER BY
  stddev_time DESC
LIMIT
  30;

SELECT 'Order by max time' AS sort_type;

SELECT
  query,
  calls,
  total_time,
  min_time,
  max_time,
  mean_time,
  stddev_time,
  rows,
  shared_blks_hit,
  shared_blks_read,
  shared_blks_dirtied,
  shared_blks_written,
  local_blks_hit,
  local_blks_read,
  local_blks_dirtied,
  local_blks_written,
  temp_blks_read,
  temp_blks_written
FROM
  pg_stat_statements
WHERE
  NOT query LIKE '%pg_catalog%'
  AND NOT query LIKE '%pg_stat%'
  AND NOT query LIKE 'BEGIN'
  AND NOT query LIKE 'COMMIT'
  AND NOT query LIKE 'ROLLBACK'
  AND NOT query LIKE 'INSERT%' -- ignore bulk inserts
ORDER BY
  max_time DESC
LIMIT
  30;
