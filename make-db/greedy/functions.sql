--create view new_best_dest as SELECT f.dest_qid, max(f.cost) AS cost, max(f.amount) AS amount                                                               FROM ( SELECT feedstock_odcosts.dest_qid, sum(feedstock.marginal_addition) OVER w AS amount, sum((feedstock.price + feedstock_odcosts.cost) * feedstock.marginal_addition) OVER w AS cost                                                               FROM feedstock_odcosts                                                     JOIN feedstock ON feedstock.qid::text = feedstock_odcosts.src_qid::text LEFT JOIN used_feedstock u using (fid) where u is NULL                                 WINDOW w AS (PARTITION BY feedstock_odcosts.dest_qid ORDER BY feedstock.price + feedstock_odcosts.cost)) f                                                   WHERE f.amount < 1000000::double precision                                      GROUP BY f.dest_qid                                                             ORDER BY max(f.cost);

-- You have the following tables:

drop schema if exists greedy cascade;
create schema greedy;
set search_path=greedy,network,public;

CREATE TABLE test (
    test character varying(8),
    type character varying(32)
);
COPY test (test, type) FROM stdin;
lce	msw_wood
lce	msw_paper
lce	forest
lce	cotton_trash
lce	straw
lce	msw_yard
lce	hec
test	cotton_trash
test	msw_yard
\.

-- Simplify feedstocks?
--create temp table lce_feedstock as 
-- select fid,qid,price,
-- sum(marginal_addition) as marginal_addition from feedstock f 
-- join feedstock_type using (type) where lce=True
-- group by qid,price;
drop table if exists feedstock_m;
create table feedstock_m as select * from feedstock.feedstock limit 0;
alter table feedstock_m add column fid serial primary key;
alter table feedstock_m add column price float;
insert into feedstock_m select * from feedstock.feedstock;
update feedstock_m set price=replace(substr(price_id,3,10),'_','.')::float;
update feedstock_m set qid='D'||substr(qid,2,7) where qid like 'M%';

--drop type if exists greedy.destination;
create type greedy.destination as 
(
 dest_qid varchar(8),
 size float,
 cost float,
 cost_per_ton float
);

--create function foo(OUT nb greedy.destination) 
create function foo(OUT dest_qid varchar(8),OUT size float,OUT cost float) 
AS $$ 
DECLARE
nb greedy.destination;
BEGIN 
RAISE INFO 'foo';
nb.dest_qid='foo';
nb.size=9999;
nb.cost=777777; 
dest_qid=nb.dest_qid;
size=nb.size;
cost=nb.cost;
END $$ LANGUAGE 'plpgsql';

create function fubar(OUT dest varchar(8)) 
AS $$
DECLARE
nb greedy.destination;
r record;
BEGIN
select foo() into r;
dest=r;
RETURN;
END
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION 
greedy.pick_refineries(test_to_run varchar(32),max_size float,skip float,
OUT final_rank integer) AS
$BODY$
  DECLARE
  nb greedy.destination;
  r record;
  total_left float;
  size_frac float;
  BEGIN

drop table if exists used_feedstock;
create temp table used_feedstock (
       fid integer primary key,
       dest_qid varchar(8),
       rank integer,
       travel_cost float );

drop table if exists built_refineries;
create temp table built_refineries (
       dest_qid varchar(8),
       "rank" integer,
       size float,
       cost float
       );

-- This is our set of feedstocks we still can use.
--create view greedy.feedstocks_in_play as 
--select fid,c.dest_qid,marginal_addition,cost as travel_cost,(price+cost) as delivered_cost
--from feedstock_odcosts c join feedstock f on (qid=src_qid)
--join greedy.test t using(type)
--left join used_feedstock u using (fid)
--where t.test=test_to_run and marginal_addition > skip and (u is null);

  final_rank:=0;
  -- Okay, we need to figure out how to estimate the feedstock size.
  -- Basically, we assume the little ones will go about the same as
  -- the big ones, and so we get the percentage of skipped and divide
  -- by the total.
  select s.sum/t.sum into size_frac 
  from (select sum(marginal_addition) 
        from feedstock_m join test using (type) where test='lce') as t,
       (select sum(marginal_addition)
        from feedstock_m join test using (type) where test='lce' 
        and marginal_addition>skip) as s;

  LOOP
--  select sum(marginal_addition) into total_left from feedstocks_in_play;
select sum(marginal_addition) into total_left
from feedstock_odcosts c join feedstock_m f on (qid=src_qid)
join greedy.test t using(type)
left join used_feedstock u using (fid)
where t.test=test_to_run and marginal_addition > skip and (u is null);

  EXIT when (total_left < max_size * size_frac + max_size * (1 - size_frac ) * final_rank ) 
         or (total_left is NULL);
  final_rank:=final_rank+1;
--  RAISE INFO 'Getting the %(th) size %',final_rank,(max_size*size_frac)::integer;
  select (greedy.next_best(test_to_run,max_size * size_frac,skip,final_rank)).dest_qid into nb.dest_qid;
  select dest_qid,size,cost,cost/size as cost_per_ton into nb from next_best_dest where size>=max_size*size_frac order by cost_per_ton asc limit 1;
--  select dest_qid,size,cost into nb from next_best_dest order by size desc, cost asc limit 1;
  RAISE INFO '%(th)=% %>% @ % per ton',final_rank,nb.dest_qid,nb.size::integer,(max_size*size_frac)::integer,nb.cost_per_ton::decimal(6,2);
  insert into built_refineries (dest_qid,rank,size,cost) values (nb.dest_qid,final_rank,nb.size,nb.cost);
--  EXIT WHEN (final_rank=7);
  END LOOP;  
  END
$BODY$
LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION 
greedy.next_best(test_to_run varchar(8),max_size float,skip float,this_rank integer,OUT nb greedy.destination) AS
$BODY$
  DECLARE
    r record;
    have_dest varchar(8);
    next_best_dest_qid varchar(8);
    cb greedy.destination;
  BEGIN
  cb.cost_per_ton=1000;
  -- These are ones used
  drop table if exists min_feedstock;
  create temp table min_feedstock (
       fid integer,
       dest_qid varchar(8),
       travel_cost float );
  -- These are summaries
  drop table if exists next_best_dest;
  create temp table next_best_dest (
       dest_qid varchar(8),
       size float,
       cost float );

--    RAISE INFO 'Ordering remaining feedstocks';
    
--      select * from feedstocks_in_play order by delivered_cost asc
    FOR r in 
select fid,c.dest_qid,marginal_addition,cost as travel_cost,
       (price+cost) as delivered_cost
from feedstock_odcosts c join feedstock_m f on (qid=src_qid)
join greedy.test t using(type)
left join used_feedstock u using (fid)
where t.test=test_to_run and marginal_addition > skip
and (u is null) 
order by delivered_cost asc, marginal_addition asc
    LOOP
--      RAISE INFO 'Adding % % at % to % in min_feedstocks',r.fid,r.marginal_addition,r.delivered_cost,r.dest_qid;
      insert into min_feedstock values (r.fid,r.dest_qid,r.travel_cost);
      select "dest_qid" into have_dest from next_best_dest where "dest_qid"=r.dest_qid; 
      IF (r.dest_qid = have_dest ) THEN
--        RAISE INFO 'Updating % by %',r.dest_qid,r.marginal_addition;
        update next_best_dest set size=size+r.marginal_addition, cost=cost+r.marginal_addition*r.delivered_cost where dest_qid=r.dest_qid;
      ELSE
--        RAISE INFO 'Inserting % by %',r.dest_qid,r.marginal_addition;
	insert into next_best_dest (dest_qid,size,cost) VALUES (r.dest_qid,r.marginal_addition,r.marginal_addition*r.delivered_cost);
      END IF;
--      select dest_qid,size,cost into nb from next_best_dest where size>=max_size order by cost/size asc limit 1;
      select dest_qid,size,cost,CASE WHEN (size<max_size) THEN ((max_size-size)*r.delivered_cost+cost)/max_size ELSE cost/size END as cost_per_ton into nb from next_best_dest order by cost_per_ton asc limit 1;
      IF ((nb.cost_per_ton != cb.cost_per_ton) or (nb.cost_per_ton=cb.cost_per_ton and nb.size>cb.size)) THEN
--          RAISE INFO 'Best possible cost_per_ton @ % is % (size=%) old % %',nb.dest_qid,nb.cost_per_ton,nb.size,cb.cost_per_ton,cb.size;
	  cb=nb;
      END IF;
      IF (nb.size > max_size) THEN 
--      RAISE INFO 'Exiting % vs %',nb.size,max_size;
      EXIT;
      END IF;
    END LOOP;
    -- Get best one
--    raise info 'Saving used_feedstocks...';
    next_best_dest_qid=nb.dest_qid;
    insert into used_feedstock (fid,dest_qid,travel_cost,rank) 
         select fid,dest_qid,travel_cost,this_rank from min_feedstock where dest_qid=nb.dest_qid;
--     drop table min_feedstock;
--     drop table next_best_dest;
    RETURN;
  END
$BODY$
LANGUAGE 'plpgsql' ;


