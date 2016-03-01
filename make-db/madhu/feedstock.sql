\set ON_ERROR_STOP 1
BEGIN;

set search_path=madhu,public;

drop table if exists feedstock;
create table feedstock as select * from feedstock.feedstock limit 0;

create temp table foo (
--create table foo (
       state varchar(55),
       county varchar(55),
       fipsi integer,
       stover40 float,straw40 float,switchgrass40 float,miscanthus40 float,
       stover50 float,straw50 float,switchgrass50 float,miscanthus50 float,
       stover60 float,straw60 float,switchgrass60 float,miscanthus60 float,
       stover70 float,straw70 float,switchgrass70 float,miscanthus70 float,
       stover80 float,straw80 float,switchgrass80 float,miscanthus80 float,
       stover90 float,straw90 float,switchgrass90 float,miscanthus90 float,
       stover100 float,straw100 float,switchgrass100 float,miscanthus100 float,
       stover120 float,straw120 float,switchgrass120 float,miscanthus120 float,
       stover140 float,straw140 float,switchgrass140 float,miscanthus140 float,
       empty float
);       

\COPY foo (state,county,fipsi,stover40,straw40,switchgrass40,miscanthus40,stover50,straw50,switchgrass50,miscanthus50,stover60,straw60,switchgrass60,miscanthus60,stover70,straw70,switchgrass70,miscanthus70,stover80,straw80,switchgrass80,miscanthus80,stover90,straw90,switchgrass90,miscanthus90,stover100,straw100,switchgrass100,miscanthus100,stover120,straw120,switchgrass120,miscanthus120,stover140,straw140,switchgrass140,miscanthus140,empty) FROM 'madhu.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER

--update vmt_by_census set fips='0'||fips where length(fips)=4;

insert into feedstock (qid,scenario,type,price,marginal_addition) 
 select fipsi,'BEPAM2030_40','stover',40,stover40 from foo f union
 select fipsi,'BEPAM2030_50','stover',50,stover50 from foo f union
 select fipsi,'BEPAM2030_60','stover',60,stover60 from foo f union
 select fipsi,'BEPAM2030_70','stover',70,stover70 from foo f union
 select fipsi,'BEPAM2030_80','stover',80,stover80 from foo f union
 select fipsi,'BEPAM2030_90','stover',90,stover90 from foo f union
 select fipsi,'BEPAM2030_100','stover',100,stover100 from foo f union
 select fipsi,'BEPAM2030_120','stover',120,stover120 from foo f union
 select fipsi,'BEPAM2030_140','stover',140,stover140 from foo f union
 select fipsi,'BEPAM2030_40','straw',40,straw40 from foo f union
 select fipsi,'BEPAM2030_50','straw',50,straw50 from foo f union
 select fipsi,'BEPAM2030_60','straw',60,straw60 from foo f union
 select fipsi,'BEPAM2030_70','straw',70,straw70 from foo f union
 select fipsi,'BEPAM2030_80','straw',80,straw80 from foo f union
 select fipsi,'BEPAM2030_90','straw',90,straw90 from foo f union
 select fipsi,'BEPAM2030_100','straw',100,straw100 from foo f union
 select fipsi,'BEPAM2030_120','straw',120,straw120 from foo f union
 select fipsi,'BEPAM2030_140','straw',140,straw140 from foo f union
 select fipsi,'BEPAM2030_40','switchgrass',40,switchgrass40 from foo f union
 select fipsi,'BEPAM2030_50','switchgrass',50,switchgrass50 from foo f union
 select fipsi,'BEPAM2030_60','switchgrass',60,switchgrass60 from foo f union
 select fipsi,'BEPAM2030_70','switchgrass',70,switchgrass70 from foo f union
 select fipsi,'BEPAM2030_80','switchgrass',80,switchgrass80 from foo f union
 select fipsi,'BEPAM2030_90','switchgrass',90,switchgrass90 from foo f union
 select fipsi,'BEPAM2030_100','switchgrass',100,switchgrass100 from foo f union
 select fipsi,'BEPAM2030_120','switchgrass',120,switchgrass120 from foo f union
 select fipsi,'BEPAM2030_140','switchgrass',140,switchgrass140 from foo f union
 select fipsi,'BEPAM2030_40','miscanthus',40,miscanthus40 from foo f union
 select fipsi,'BEPAM2030_50','miscanthus',50,miscanthus50 from foo f union
 select fipsi,'BEPAM2030_60','miscanthus',60,miscanthus60 from foo f union
 select fipsi,'BEPAM2030_70','miscanthus',70,miscanthus70 from foo f union
 select fipsi,'BEPAM2030_80','miscanthus',80,miscanthus80 from foo f union
 select fipsi,'BEPAM2030_90','miscanthus',90,miscanthus90 from foo f union
 select fipsi,'BEPAM2030_100','miscanthus',100,miscanthus100 from foo f union
 select fipsi,'BEPAM2030_120','miscanthus',120,miscanthus120 from foo f union
 select fipsi,'BEPAM2030_140','miscanthus',140,miscanthus140 from foo f
;

delete from feedstock where marginal_addition is Null;
update madhu.feedstock set qid='S0'||qid where length(qid)=4;
update madhu.feedstock set qid='S'||qid where length(qid)=5;


\echo The following feedstocks are bad
select distinct f.qid from feedstock f left join network.county c using(qid) where c is null;

END;
