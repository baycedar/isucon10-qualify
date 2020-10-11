-- vacuum and analyze tables
VACUUM ANALYZE chair;

-- reset statistics
SELECT pg_stat_statements_reset();

-- fetch initial data in memory
SELECT pg_prewarm('chair', 'prefetch');
