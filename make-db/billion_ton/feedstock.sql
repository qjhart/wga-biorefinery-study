\set ON_ERROR_STOP 1
set search_path=billion_ton,public;

create temp table forest_cumulative as 
select distinct qid,scenario||' '||basis as scenario,feedstck,price,
production 
from supply
where feedstck in ('LOGR','LOGO','LOGP','LOGT','LOGTOF','LOGRLOGT',
                   'MRESUU','UWDWCD','UWDWMS') 
and year=2022;-- and scenario is not null and basis is not null;

create temp table forest_previous as 
select distinct qid,scenario||' '||basis as scenario,feedstck,
price+10 as price,
production 
from supply 
where feedstck in ('LOGR','LOGO','LOGP','LOGT','LOGTOF','LOGRLOGT',
                   'MRESUU','UWDWCD','UWDWMS') 
and year=2022; --and scenario is not null and basis is not null;

create table feedstock as
select qid,scenario,feedstck as type,price,
production as marginal_addition 
from forest_cumulative x 
where price=10
union
select qid,scenario,feedstck as type,price,
x.production-n.production as marginal_addition 
from forest_cumulative x 
join forest_previous n 
using (scenario,feedstck,qid,price);
--where x.production != n.production;
delete from feedstock where marginal_addition=0;
