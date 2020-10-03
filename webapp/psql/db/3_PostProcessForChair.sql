-- vacuum and analyze tables
VACUUM ANALYZE chair;

-- reset statistics
SELECT pg_stat_statements_reset();
