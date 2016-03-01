You have the following tables:
built_refineries:= dest_qid,rank,cost
feedstocks:= feedstock_id,src_qid,type,cost,marginal_addition
feedstocks_odcosts:src_id,dest_id,cost
used_feedstocks:= dest_qid,feedstock_id,travel_cost?

truncate built_refineries;
rank:=0
do until no more feedstocks;
  \info Getting rank(thed) best refinery
  rank:=rank+1;
  create temp table next_best as select next_best_refinery();
  nb := select sum(cost) from next_best
  insert into built_refineries (dest_qid,rank,cost) 
       values (nb.qid,rank,nb.cost);
  \info Next best is nb.qid, cost=nb.cost
  \info Marking Feedstocks....
  insert into used_feedstocks (dest_qid,feedstock_id,cost) select * fromm nest_best;
  \info Marked num
done;

CREATE OR REPLACE FUNCTION 
best_dest(qid_of_interest varchar(12),size float,
OUT amount float, OUT total_cost float) AS
$BODY$
  DECLARE
    r record;
  BEGIN
    total_cost := 0;
    amount := 0;
    FOR r in select qid, marginal_addition, 
                         (price+cost)*marginal_addition as cost 
             from feedstock_odcosts c join feedstock f on (qid=src_qid) left join used_feedstocks u using (feedstock_id)  
	     where dest_qid=qid_of_interest
	     and ((u is null) or u.cost > (price+cost)*marginal_addition)
             order by (price+cost) asc
    LOOP
      IF (amount >= size) THEN
        EXIT;
      ELSE 
#        RETURN next output_type;
#      END IF;
      amount:= amount + r.marginal_addition;
      total_cost := total_cost+r.cost;
    END LOOP;
    RETURN;
  END
$BODY$
LANGUAGE 'plpgsql' ;

-- CREATE OR REPLACE FUNCTION greedy.best_dest(qid varchar(12),size float,OUT cost float)
-- $BODY$
--   DECLARE
--     r rowtype;
--     sofar float;
--   BEGIN
--     cost := 0;
--     amount := 0;
--     FOR r in select qid, marginal_addition, (price+cost)*marginal_addition as cost from feedstock_odcosts join feedstock on (qid=src_qid) order by (price+cost) asc;
--     LOOP
--       IF (amount >= total) THEN
--         EXIT;
--       ELSE 
--         RETURN NEXT r.pfarm_gid;
--       END IF;
--       sofar := sofar+r.arable;
--     END LOOP;
--     RETURN;
--   END
-- $BODY$
-- LANGUAGE 'plpgsql' ;
