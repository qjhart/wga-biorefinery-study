\set ON_ERROR_STOP 1
BEGIN;
\set s msw
\set t pop_growth
\set st msw.pop_growth

set search_path=:s,public;

drop table if exists :st;
create table :st (
       state_fips varchar(2),
       year0 float,
       population float,
       exp float
);       

create temp table foo (
       state varchar(55),
       pop2000 float,
       pop2030 float,
       exp float
);       

COPY foo (state,pop2000,pop2030,exp) FROM 'pop_growth.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

insert into :st (state_fips,year0,population,exp) select s.state_fips,2000,pop2000,ln(pop2030/pop2000)/30.0 from foo f join network.state s using (state);

\echo The following states are not good
select f.state from foo f left join network.state s using(state) where s is null;

\echo Making functions
CREATE OR REPLACE FUNCTION msw.population_growth(county_fips char(5), year_from float, year_to float, OUT growth float) 
AS $$ 
select exp(exp*($3-$2)) as growth 
from msw.pop_growth where state_fips=substr($1,1,2) 
$$ LANGUAGE 'sql';

END;
