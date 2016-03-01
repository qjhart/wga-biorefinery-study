--select rank,dest_qid,total_bdt::integer,total_fuel::integer,total_feedstock_cost::integer,total_cost::integer,levelized_bdt_cost::decimal(6,2),levelized_fuel_cost::decimal(6,2),max_feed_for_min_levelized_cost::decimal(6,2) as max_feed from (select s.*,(greedy.refinery_costs('lce',total_bdt/0.448,total_fuel/0.448,total_feedstock_cost/0.448,2.08)).* from (select rank,dest_qid,sum(marginal_addition) as total_bdt,sum(fuel_addition) as total_fuel,sum(marginal_addition*delivered_cost) as total_feedstock_cost from used_feedstock group by rank,dest_qid) as s) as f order by rank;

SET SEARCH_PATH=greedy,public;

drop type destination;
create type destination as 
(
 dest_qid varchar(8),
 size float,
 cost float,
 cost_per_ton float,
 max_feedstock_price float
);

CREATE OR REPLACE FUNCTION 
greedy.prepare_tables(technology_id varchar(8),skip float,
OUT total_feedstock float,OUT included_fraction float) AS
$BODY$
DECLARE
  feedstock_types text[];
BEGIN
  select types into feedstock_types from greedy.technology where tech=technology_id;

--  RAISE INFO 'Creating new feedstock table';
  drop table if exists feedstock_m;
  create temp table feedstock_m (
    fid serial,
    qid varchar(8),
    type varchar(24),
    marginal_addition float,
    price float);

  insert into feedstock_m (qid,type,marginal_addition,price) 
  select qid,type,marginal_addition,replace(substr(price_id,3,10),'_','.')::float as price 
  from feedstock.feedstock where type=ANY(feedstock_types);

  -- Okay, we need to figure out how to estimate the feedstock size to shoot for.
  -- Basically, we assume the little ones will go about the same as
  -- the big ones, and so we get the percentage of skipped and divide
  -- by the total.
  select s.sum/t.sum into included_fraction 
  from (select sum(marginal_addition) 
        from feedstock_m ) as t,
       (select sum(marginal_addition)
        from feedstock_m
        where marginal_addition>skip) as s;

  -- delete little ones
  delete from feedstock_m where marginal_addition <=skip ;
  -- fix some qids
  update feedstock_m set qid='D'||substr(qid,2,7) where qid like 'M%';
  -- add index on qid
  create index feedstock_m_qid on feedstock_m(qid);

  select sum(marginal_addition) into total_feedstock from feedstock_m;

  RAISE INFO 'creating feedstock_costs';
--  truncate greedy.feedstock_costs;
  drop table if exists greedy.feedstock_costs;
  create table greedy.feedstock_costs (
   cid serial primary key,
   fid integer,
   dest_qid varchar(8),
   marginal_addition float,
   fuel_addition float,
   travel_cost float,
   delivered_cost float,
   rank integer default NULL
  );

--  perform setval('greedy.feedstock_costs_cid_seq',1);
  insert into greedy.feedstock_costs (fid,dest_qid,marginal_addition,fuel_addition,travel_cost,delivered_cost) 
    select fid,c.dest_qid,marginal_addition,marginal_addition*gal_per_bdt as fuel_addition, cost as travel_cost,
           (price+cost) as delivered_cost
    from network.feedstock_odcosts c join feedstock_m f on (qid=src_qid) 
    join greedy.conversion_efficiency using (type)
    where tech=technology_id
    and gal_per_bdt>0
    order by delivered_cost,marginal_addition;

  create index feedstock_cost_fid on greedy.feedstock_costs(fid);
  create index feedstock_cost_rank on greedy.feedstock_costs(rank);
  create index feedstock_cost_delivered_cost on greedy.feedstock_costs(delivered_cost);
    
  -- These are running summaries
  drop table if exists next_best_dest cascade;
  create table greedy.next_best_dest (
       dest_qid varchar(8) primary key,
       size float default 0,
       cost float default 0,
       cost_per_ton float default 10000,
       max_feedstock_price float default 10000
 );

  insert into greedy.next_best_dest (dest_qid) select distinct dest_qid 
  from greedy.feedstock_costs;

  create index next_best_dest_dest_qid on greedy.next_best_dest(dest_qid);
  create index next_best_dest_cost_per_ton on greedy.next_best_dest(cost_per_ton);

END
$BODY$
LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION 
greedy.build_refineries(technology_id varchar(8),skip float,
OUT rank_count integer) AS
$BODY$
  DECLARE
  max_sz float;
  tot_feed float;
  total_so_far float;
  feed greedy.feedstock_costs%ROWTYPE;
  size_frac float; -- How much of the feedstock we shoot for.
  old_rank_count integer;
  this_best greedy.destination; -- next_best_dest%ROWTYPE;
  current_best greedy.destination;
  next_best greedy.destination;
  last_cid integer;
  price_for_fuel float;
  affected_cids integer[];
  affected_fids integer[];
  affected_dest_qids varchar(8)[];
-- cnt integer;
  BEGIN

  price_for_fuel:=2.08; -- Currently not really used

  rank_count := 1;
  current_best.size := 0;
  total_so_far := 0;
  last_cid:=0;

select max_size INTO max_sz
from greedy.technology 
where tech=technology_id;

--  select total_feedstock,included_fraction into tot_feed,size_frac from (select total_feedstock,included_fraction from greedy.prepare_tables(technology_id,skip)) as f;
  select total_feedstock,included_fraction
  INTO tot_feed,size_frac
  from greedy.prepare_tables(technology_id,skip);

  RAISE INFO 'tot_feed=%,size_frac=%',tot_feed,size_frac;
  max_sz = max_sz*size_frac;

  RAISE INFO 'Finding about % refineries of size % from total %',floor(tot_feed/max_sz),max_sz::integer,tot_feed::integer;

  select into feed -1::integer as cid,0::float as delivered_cost;

  << all_refineries>>
  LOOP
-- cnt:=0;
    <<next_refinery>>
    FOR feed in 
    select * from greedy.feedstock_costs
    where cid>feed.cid and rank is NULL
    order by cid asc
    LOOP
-- cnt:=cnt+1;

    select dest_qid,size,cost,size,cost_per_ton,max_feedstock_price
    into this_best
    from greedy.next_best_dest 
    where dest_qid=feed.dest_qid;

    IF (feed.delivered_cost > this_best.max_feedstock_price) THEN
      RAISE INFO 'Was % is % BDT @  % $ or % $/bdt can pay up to % $/bdt',this_best.dest_qid,
                   this_best.size,this_best.cost,this_best.cost_per_ton,this_best.max_feedstock_price;
      RAISE INFO 'Nothing helps bye!';
      EXIT all_refineries;
    END IF;

    IF (feed.delivered_cost < this_best.max_feedstock_price) THEN

    update greedy.next_best_dest nb 
    set size=n.total_bdt, 
        cost=n.total_cost,
	cost_per_ton=n.levelized_bdt_cost,
	max_feedstock_price=n.max_feed_for_max_profit from
        (select s.*,
                (greedy.refinery_costs(technology_id,
                                          total_bdt/size_frac,total_fuel/size_frac,tot_feed_cost/size_frac,
		                          price_for_fuel)).* 
         from (select
                      sum(marginal_addition) as total_bdt,
                      sum(fuel_addition) as total_fuel, 
                      sum(marginal_addition*delivered_cost) as tot_feed_cost 
               from greedy.feedstock_costs
               where dest_qid=feed.dest_qid and rank is NULL and cid<=feed.cid
	      )  as s
        ) as n
        where dest_qid=feed.dest_qid;

      select dest_qid,size,cost,cost_per_ton,max_feedstock_price
      into this_best
      from greedy.next_best_dest 
      where dest_qid=feed.dest_qid;
--      RAISE INFO 'Now % is % BDT @  % $ or % $/bdt can pay up to % $/bdt',this_best.dest_qid,
--                  this_best.size,this_best.cost,this_best.cost_per_ton,this_best.max_feedstock_price;

     old_rank_count:=rank_count;

     <<pop_refineries>>
     LOOP 
     select dest_qid,size,cost,cost_per_ton,max_feedstock_price
     into next_best
     from greedy.next_best_dest 
     order by cost_per_ton asc,size desc 
     limit 1;

        -- pop off refinery
        IF (next_best.max_feedstock_price < feed.delivered_cost) THEN 
BEGIN
          total_so_far := total_so_far + next_best.size;

          RAISE INFO '# %=% % BDT @ % $/BDT (%) cid=% (%<%)',rank_count,next_best.dest_qid,
                 next_best.size::integer,next_best.cost_per_ton::decimal(6,2),
		 (total_so_far/tot_feed)::decimal(4,2),feed.cid,
		 next_best.max_feedstock_price,feed.delivered_cost;

          -- only remove the ones we actually used. 
          select array
          (
           select cid 
           from (select dest_qid,fid,cid,delivered_cost,
              sum(marginal_addition) OVER w as total_bdt,
              sum(fuel_addition) OVER w as total_fuel,
              sum(marginal_addition*delivered_cost) OVER w as tot_feed_cost
            from greedy.feedstock_costs 
            where dest_qid=next_best.dest_qid and rank is NULL and cid<=feed.cid
            WINDOW w as (order by cid)) as s
           where ((greedy.refinery_costs(technology_id,total_bdt/size_frac,total_fuel/size_frac,tot_feed_cost/size_frac,price_for_fuel)).max_feed_for_max_profit >= feed.delivered_cost)
	   union
           (select cid 
           from (select dest_qid,fid,cid,delivered_cost,
              sum(marginal_addition) OVER w as total_bdt,
              sum(fuel_addition) OVER w as total_fuel,
              sum(marginal_addition*delivered_cost) OVER w as tot_feed_cost
            from greedy.feedstock_costs
            where dest_qid=next_best.dest_qid and rank is NULL and cid<=feed.cid
            WINDOW w as (order by cid)) as s
           where ((greedy.refinery_costs(technology_id,total_bdt/size_frac,total_fuel/size_frac,tot_feed_cost/size_frac,price_for_fuel)).max_feed_for_max_profit < feed.delivered_cost)
	   limit 1)
           ) INTO affected_cids;

          -- Find affected refineries
          select array(select distinct fid
                        from greedy.feedstock_costs 
                        where cid=ANY(affected_cids)) 
          INTO affected_fids;

          -- Find affected refineries
          select array(select distinct dest_qid 
                        from greedy.feedstock_costs 
                        where fid=ANY(affected_fids) and cid<=feed.cid and rank is NULL) 
          INTO affected_dest_qids;

          RAISE INFO '## fids=% dest_qids=%',affected_fids,affected_dest_qids;

          update greedy.feedstock_costs set rank=rank_count
          where cid=ANY(affected_cids);

	  update greedy.next_best_dest nb
          set size=0,
              cost=0,
  	      cost_per_ton=10000,
	      max_feedstock_price=10000
          where nb.dest_qid=next_best.dest_qid;

          -- Remove ones which might come later
          update greedy.feedstock_costs set rank=-1
          where fid=ANY(affected_fids) and rank is NULL;

          update greedy.next_best_dest nb 
          set size=n.total_bdt,
              cost=n.total_cost,
  	      cost_per_ton=n.levelized_bdt_cost,
	      max_feedstock_price=n.max_feed_for_max_profit
          from
         (select s.dest_qid,s.total_bdt,s.total_fuel,
                 (greedy.refinery_costs(technology_id,
                                          total_bdt/size_frac,total_fuel/size_frac,tot_feed_cost/size_frac,
		                          price_for_fuel)).* 
          from (select dest_qid,
                      sum(marginal_addition) as total_bdt,
                      sum(fuel_addition) as total_fuel, 
                      sum(marginal_addition*delivered_cost) as tot_feed_cost 
               from greedy.feedstock_costs
               where dest_qid=ANY(affected_dest_qids) and rank is NULL and cid<=feed.cid
	       GROUP BY dest_qid
	      )  as s
         ) as n
          where nb.dest_qid=n.dest_qid;

     rank_count=rank_count+1;
END;
    IF (rank_count > 20) THEN
       EXIT all_refineries;
    END IF;

      ELSE
        EXIT pop_refineries;
      END IF;

      END LOOP pop_refineries;

      IF (rank_count > old_rank_count) THEN
        EXIT next_refinery;
      END IF;

      IF ((next_best.dest_qid != current_best.dest_qid) or 
          (next_best.size>current_best.size)) or 
          (next_best.cost_per_ton > current_best.cost_per_ton+0.5) or
  	  (feed.cid > last_cid+2000)
      THEN
         RAISE INFO 'Maybe % - % BDT (%) @ % $/BDT cid=% @ % $/BDT',
 	    next_best.dest_qid,next_best.size::integer,(next_best.size/max_sz)::decimal(4,2),
	    next_best.cost_per_ton::decimal(6,2),
	    feed.cid,feed.delivered_cost::decimal(6,2);
 	    current_best=next_best;
	    last_cid=feed.cid;
      END IF;

    END IF;

--    IF (cnt > 100) THEN
--       EXIT all_refineries;
--    END IF;

    END LOOP next_refinery;

    END LOOP all_refineries;

    RETURN;
  END
$BODY$
LANGUAGE 'plpgsql' ;

