\set ON_ERROR_STOP 1
--BEGIN;

set search_path=nelson,public;

drop table if exists yield;
create table yield (
       qid varchar(8),
       type varchar(8),
       yield float,
       acres float
);       

drop table if exists residue;
create table residue (
       qid varchar(8),
       type varchar(8),
       yield float,
       residue float
);       

drop table if exists commodities;
create table commodities (
	code varchar(8),
	commodity varchar(8)
);

COPY commodities (code,commodity) FROM STDIN WITH CSV HEADER;
code,commodity
cg,cg
sb,sb
gs,gs
ww,wheat
sw,wheat
br,barley
ot,ot
ctu,ctu
can,can
sun,sun
rice,rice
sg,gs
wheat,wheat
barley,barley
oat,oat
rye,rye
cot,cot
fla,fla
saf,saf
pot,pot
\.

create temp table y (
	code varchar(8),
	fips varchar(8),
	cgy float,
	cga float,
	Sby float,
	Sba float,
	GSy float,
	Gsa float,
	Wwy float,
	Wwa float,
	SWy float,
	SWA float,
	Bry float,
	Bra float,
	oty float,
	ota float,
	ctuy float,
	ctua float,
	cany float,
	cana float,
	suny float,
	suna float,
	ricey float,
	ricea float);

\COPY y (CODE,FIPS,cgy,cga,Sby,Sba,GSY,Gsa,Wwy,Wwa,SWY,SWA,Bry,Bra,oty,ota,ctuy,ctua,cany,cana,suny,suna,ricey,ricea) FROM 'yield.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER

update y set code=substr(code,1,2)||repeat('0',5-length(code))||substring(code,3,10);

insert into yield (qid,type,yield,acres) select
'S'||fips,'cg',cgy,cga from y
union
select 'S'||fips,'sb',sby,sba from y
union
select 'S'||fips,'gs',gsy,gsa from y
union
select 'S'||fips,'ww',wwy,wwa from y
union
select 'S'||fips,'sw',swy,swa from y
union
select 'S'||fips,'br',bry,bra from y
union
select 'S'||fips,'ot',oty,ota from y
union
select 'S'||fips,'ctu',ctuy,ctua from y
union
select 'S'||fips,'can',cany,cana from y
union
select 'S'||fips,'sun',suny,suna from y
union
select 'S'||fips,'rice',ricey,ricea from y
;

-- update yield y set type=commodity from commodities c where y.type=c.code;

create temp table r (
       code varchar(8),
       fips varchar(8),
       cmz varchar(5),
       total_acres float,
       residue float,
       avg_res_acre float,
       cgy float,
       cgr float,
       sgy float,
       sgr float,
       sby float,
       sbr float,
       wheaty float,
       wheatr float,
       barleyy float,
       barleyr float,
       oaty float,
       oatr float,
       ryey float,
       ryer float,
       coty float,
       cotr float,
       suny float,
       sunr float,
       flay float,
       flar float,
       safy float,
       safr float,
       cany float,
       canr float,
       poty float,
       potr float);

\COPY r (fips,code,cmz,total_acres,residue,avg_res_acre,cgy,cgr,sgy,sgr,sby,sbr,wheaty,wheatr,barleyy,barleyr,oaty,oatr,ryey,ryer,coty,cotr,suny,sunr,flay,flar,safy,safr,cany,canr,poty,potr) FROM 'residue.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER

insert into residue (qid,type,yield,residue) 
select 'S'||y.fips,'cg',r.cgy,r.cgr from r join y using (code)
union
select 'S'||y.fips,'sg',r.sgy,r.sgr from r join y using (code)
union
select 'S'||y.fips,'sb',r.sby,r.sbr from r join y using (code)
union
select 'S'||y.fips,'wheat',r.wheaty,r.wheatr from r join y using (code)
union
select 'S'||y.fips,'barley',r.barleyy,r.barleyr from r join y using (code)
union
select 'S'||y.fips,'oat',r.oaty,r.oatr from r join y using (code)
union
select 'S'||y.fips,'rye',r.ryey,r.ryer from r join y using (code)
union
select 'S'||y.fips,'cot',r.coty,r.cotr from r join y using (code)
union
select 'S'||y.fips,'sun',r.suny,r.sunr from r join y using (code)
union
select 'S'||y.fips,'fla',r.flay,r.flar from r join y using (code)
union
select 'S'||y.fips,'saf',r.safy,r.safr from r join y using (code)
union
select 'S'||y.fips,'can',r.cany,r.canr from r join y using (code)
union
select 'S'||y.fips,'pot',r.poty,r.potr from r join y using (code)
;

delete from residue where residue=0;

--END;

-- \echo The following states are not good
-- select f.state from foo f left join network.state s using(state) where s is null;
