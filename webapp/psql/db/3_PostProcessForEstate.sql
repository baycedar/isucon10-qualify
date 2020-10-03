-- vacuum and analyze tables
VACUUM ANALYZE estate;

-- reset statistics
SELECT pg_stat_statements_reset();
