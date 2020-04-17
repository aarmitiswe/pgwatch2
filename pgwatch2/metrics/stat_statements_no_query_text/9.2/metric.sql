with q_data as (
    select
        (extract(epoch from now()) * 1e9)::int8 as epoch_ns,
        (regexp_replace(md5(query), E'\\D', '', 'g'))::varchar(10)::int8 as tag_queryid,
        '-' as tag_query,
        array_to_string(array_agg(distinct quote_ident(pg_get_userbyid(userid))), ',') as users,
        sum(s.calls)::int8 as calls,
        round(sum(s.total_time)::numeric, 3)::double precision as total_time,
        sum(shared_blks_hit)::int8 as shared_blks_hit,
        sum(shared_blks_read)::int8 as shared_blks_read,
        sum(shared_blks_written)::int8 as shared_blks_written,
        sum(shared_blks_dirtied)::int8 as shared_blks_dirtied,
        sum(temp_blks_read)::int8 as temp_blks_read,
        sum(temp_blks_written)::int8 as temp_blks_written,
        round(sum(blk_read_time)::numeric, 3)::double precision as blk_read_time,
        round(sum(blk_write_time)::numeric, 3)::double precision as blk_write_time
    from
        get_stat_statements() s
    where
            calls > 5
      and total_time > 0
      and dbid = (select oid from pg_database where datname = current_database())
      and not upper(s.query) like any (array['DEALLOCATE%', 'SET %', 'RESET %', 'BEGIN%', 'BEGIN;',
        'COMMIT%', 'END%', 'ROLLBACK%', 'SHOW%'])
    group by
        tag_queryid
)
select * from (
                  select
                      *
                  from
                      q_data
                  where
                          total_time > 0
                  order by
                      total_time desc
                  limit 100
              ) a
union
select * from (
                  select
                      *
                  from
                      q_data
                  order by
                      calls desc
                  limit 100
              ) a
union
select * from (
                  select
                      *
                  from
                      q_data
                  where
                          shared_blks_read > 0
                  order by
                      shared_blks_read desc
                  limit 100
              ) a
union
select * from (
                  select
                      *
                  from
                      q_data
                  where
                          shared_blks_written > 0
                  order by
                      shared_blks_written desc
                  limit 100
              ) a
union
select * from (
                  select
                      *
                  from
                      q_data
                  where
                          temp_blks_read > 0
                  order by
                      temp_blks_read desc
                  limit 100
              ) a
union
select * from (
                  select
                      *
                  from
                      q_data
                  where
                          temp_blks_written > 0
                  order by
                      temp_blks_written desc
                  limit 100
              ) a;
