drop schema if exists greedy cascade;
create schema greedy;
set search_path=greedy,public;

-- Create our technologies, conversions, etc.
create table technology
(
 tech varchar(8) primary key,
 max_size integer,
 min_size integer,
 types character varying(32)[]
);
COPY technology (tech,max_size,min_size,types) FROM STDIN DELIMITER '|'; 
drymill|\N|\N|{corngrain}
lce|1000000|100000|{ag,cotton_trash,hec,forest.log,forest.mill,forest.other,forest.thin,msw.paper,msw.yard,msw.wood}
pulp|\N|\N|{pulpwood}
biod|\N|\N|{canola_oil,grease,lard_cwg,soybean_oil,tallow}
pyr|\N|\N|{msw.dirty}
\.

CREATE TABLE test (
       test_id serial,
       name character varying(32) unique,
       tech varchar(8) references technology(tech),
       skip float,
       scenarios character varying(32)[]
);
COPY test (name, tech, skip, scenarios) FROM stdin WITH DELIMITER '|';
lce100k|lce|100000|{all,all forest,msw,wga,no_past_high,usfs}
lce|lce|8000|{all,all forest,msw,wga,no_past_high,usfs}
msw|lce|100000|{msw}
high|lce|25000|{all,all forest,msw,nass,past_high,usfs}
low|lce|25000|{all,non-fed forest,msw,wga,no_past_low,usfs}
mid|lce|100000|{all,all forest,msw,wga,no_past_high,usfs}
\.

--all,all forest,msw, nass, non-fed forest, no_past_high, no_past_low, past_high, past_low, usfs, wga

create table conversion_efficiency
(
  tech varchar(8) references technology,
  type varchar(24),
  gal_per_bdt float,
  primary key (tech,type)
);

-- This table gets removed and recreated maybe?
create table feedstock_costs (
  cid serial primary key,
  fid integer,
  dest_qid varchar(8),
  marginal_addition float,
  fuel_addition float,
  travel_cost float,
  delivered_cost float,
  rank integer default NULL
);

CREATE OR REPLACE FUNCTION 
greedy.refinery_costs(technology_id varchar(8),
total_bdt float,total_gal float,total_feedstock_cost float,
exp_price_gal float,
OUT total_cost float, OUT levelized_bdt_cost decimal(6,2), OUT levelized_fuel_cost decimal(6,2),
OUT max_feed_for_min_levelized_cost decimal(6,2),OUT max_feed_for_max_profit decimal(6,2)) AS
$BODY$
DECLARE
conversion_cost float;
amt_cap_cost float;
operating_cost float;
min_cap_bdt float;
max_cap_bdt float;
acc_cons float;
BEGIN
conversion_cost:=25.559;

select min_size,max_size INTO min_cap_bdt,max_cap_bdt
from greedy.technology 
where tech=technology_id;

operating_cost:=conversion_cost*total_bdt;

acc_cons:=0.123*265248552/(924863^0.8);
amt_cap_cost:=acc_cons*(GREATEST(min_cap_bdt,total_bdt))^0.8;
total_cost:=(amt_cap_cost+total_feedstock_cost+operating_cost);

levelized_bdt_cost:=total_cost/total_bdt;
levelized_fuel_cost:=total_cost/total_gal;

IF (total_bdt>max_cap_bdt) THEN
  max_feed_for_min_levelized_cost:=0;
  max_feed_for_max_profit:=0;

ELSIF (total_bdt<min_cap_bdt) THEN

  max_feed_for_min_levelized_cost:=total_feedstock_cost/total_bdt+0.2*acc_cons;
  max_feed_for_max_profit:=exp_price_gal*(total_gal/total_bdt)-conversion_cost
                           -Amt_cap_cost/total_bdt;
ELSE
  max_feed_for_min_levelized_cost:=total_feedstock_cost/total_bdt+0.2*acc_cons*total_bdt^(-0.2);
  max_feed_for_max_profit:=exp_price_gal*(total_gal/total_bdt)-conversion_cost
                           -Amt_cap_cost/total_bdt;
END IF;
max_feed_for_max_profit:=GREATEST(max_feed_for_max_profit,max_feed_for_min_levelized_cost);
END
$BODY$
LANGUAGE 'plpgsql' IMMUTABLE ;




