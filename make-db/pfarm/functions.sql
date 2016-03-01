-- CREATE OR REPLACE FUNCTION pfarm.truncated_grid_box(g geometry, i integer, t double precision)
--   RETURNS box2d AS
-- $BODY$
--   RETURN makebox2d(makepoint((floor(xmin(g)/i+t)*i)::int,(floor(ymin(g)/i+t)*i)::int),makepoint((ceil(xmax(g)/i-t)*i)::int,(ceil(ymax(g)/i-t)*i)::int));
-- $BODY$
--   LANGUAGE 'plpgsql' VOLATILE;

CREATE OR REPLACE FUNCTION pfarm.truncated_grid_box(g geometry, i integer, t double precision)
  RETURNS box2d AS
$BODY$
  select makebox2d(makepoint((floor(xmin($1)/$2+$3)*$2)::int,(floor(ymin($1)/$2+$3)*$2)::int),makepoint((ceil(xmax($1)/$2-$3)*$2)::int,(ceil(ymax($1)/$2-$3)*$2)::int));
$BODY$
  LANGUAGE 'sql' VOLATILE;

CREATE OR REPLACE FUNCTION pfarm.grid_boxes(g geometry, i integer, t double precision)
  RETURNS SETOF box2d AS
$BODY$
  DECLARE
    b box2d;
    s integer;
  BEGIN
    b := pfarm.truncated_grid_box(g,i,t);
    RETURN QUERY select box from (select makebox2d(makepoint(x,y),makepoint(x+i,y+i)) as box from
      (select generate_series(xmin::int,xmax::int,i) as x,y from 
        (select floor(xmin(l)/i)*i::int as xmin,(floor(xmax(l)/i)*i)::int as xmax,y from
          (select y,st_collect(st_intersection(setsrid(makeline(makepoint(xmin(b),y),makepoint(xmax(b),y)),srid(g)),g),st_intersection(setsrid(makeline(makepoint(xmin(b),y+i),makepoint(xmax(b),y+i)),srid(g)),g)) as l from (select generate_series(ymin(b)::int,(ymax(b)-i)::int,i) as y) as ylines ) as lines ) as bounded_lines ) as grid_ll_points) as allboxes where intersects(setsrid(allboxes.box,srid(g)),g) and area(intersection(setsrid(allboxes.box,srid(g)),g))/area(setsrid(allboxes.box,srid(g)))>t;
   END
$BODY$
  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION pfarm.grid_boxes_trojan(g geometry, i integer, t double precision)
  RETURNS SETOF box2d AS
$BODY$
   select * from pfarm.grid_boxes($1,$2,$3);
$BODY$
  LANGUAGE 'sql' VOLATILE;


CREATE or replace FUNCTION refresh_pfarm_materialized_views() RETURNS integer AS $$
DECLARE
     mviews RECORD;
BEGIN
--    PERFORM cs_log('Refreshing materialized views...');
    RAISE INFO 'Refreshing materialized views...';
    FOR mviews IN SELECT * FROM materialized_views ORDER BY sort_order LOOP
--        PERFORM cs_log('Refreshing materialized view ' || quote_ident(mviews.view) || ' ...');
        RAISE INFO 'Refreshing materialized view ';
        EXECUTE 'TRUNCATE m_' || quote_ident(mviews.view);
        EXECUTE 'INSERT INTO m_' || quote_ident(mviews.view) || ' SELECT * FROM ' || quote_ident(mviews.view);
    END LOOP;
--    PERFORM cs_log('Done refreshing materialized views.');
      RAISE INFO 'Done refreshing materialized views.';
    RETURN 1;
END;
$$ LANGUAGE plpgsql;

-- CREATE or replace FUNCTION refresh_pfarm_materialized_views() RETURNS integer AS $$
-- DECLARE
--      mviews RECORD;
-- BEGIN
-- --    PERFORM cs_log('Refreshing materialized views...');
--     FOR mviews IN SELECT * FROM materialized_views ORDER BY sort_order LOOP
-- --        PERFORM cs_log('Refreshing materialized view ' || quote_ident(mviews.tablename) || ' ...');
--         EXECUTE 'TRUNCATE TABLE ' || quote_ident(mviews.tablename);
--         EXECUTE 'INSERT INTO ' || quote_ident(mviews.tablename) || ' ' || mviews.query;
--     END LOOP;
-- --    PERFORM cs_log('Done refreshing materialized views.');
--     RETURN 1;
-- END;
-- $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pfarm.return_pfarms(co_gid integer,cid integer,total double precision)
  RETURNS SETOF integer AS
$BODY$
  DECLARE
    r pfarm.pfarm_crop_score%rowtype;
    sofar float;
  BEGIN
    sofar := 0;
    FOR r in select * FROM pfarm.m_pfarm_crop_score join pfarm.pfarm_county using (pfarm_gid) where county_gid=co_gid and crop_id=cid order by nonirr_score desc
    LOOP
      IF (sofar >= total) THEN
        EXIT;
      ELSE 
        RETURN NEXT r.pfarm_gid;
      END IF;
      sofar := sofar+r.arable;
    END LOOP;
    RETURN;
  END
$BODY$
LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION pfarm.return_pfarms_trojan(co_gid integer,cid integer,total double precision)
  RETURNS SETOF integer AS
$BODY$
   select * from pfarm.return_pfarms($1,$2,$3);
$BODY$
  LANGUAGE 'sql' VOLATILE;


