set search_path=refineries,network,public;

-- No national sewage data yet.
-- create or replace view sewage_location as 
-- select qid, True as sewage 
-- from city_parameters p  where p.parameter='sewage';

create or replace view refineries.has_populated as 
select distinct qid, True as populated
from network.place cx where cx.pop_2000>10000;

create or replace VIEW refineries.has_railway as 
select gid,qid, True as railway 
from network.place c join network.place_railwaynode r  
on (c.gid=r.p_gid);

create or replace VIEW refineries.has_fuel_port as
select gid,qid,True as fuel_port 
from network.place p join network.place_fuel_port fp on (p.gid=fp.p_gid);

create or replace VIEW refineries.has_connected as
select qid,fuel_port as connected
from has_fuel_port
union 
select qid,railway as connected 
from has_railway;

create or replace view refineries.has_epa as 
select distinct qid, True as epa
from refineries.epa_facility;

create or replace view refineries.has_pulpmill as 
select distinct qid, True as pulpmill
from forest.pulpmills;

create or replace view refineries.has_biopower as 
select distinct qid, True as biopower
from refineries.biopower_facility;

create or replace view refineries.has_terminal as 
select distinct qid, True as terminal
from refineries.terminals;


create or replace view refineries.has_ethanol as 
select distinct qid, True as ethanol
from refineries.ethanol_facility;


create or replace VIEW refineries.has_similar as
select qid,epa as similar
from refineries.has_epa
union
select qid,pulpmill as similar
from refineries.has_pulpmill
union 
select qid,biopower as similar
from refineries.has_biopower
union
select qid,ethanol as similar
from refineries.has_ethanol
union
select qid,terminal as similar
from refineries.has_terminal;

-- Potential locations is pretty simple.  It's just any location has
-- is connected and is either populated enough, or has an existing
-- epa_facility, ethanol plant, or biopower facility.  Since none of
-- the facilities are cellulosic, we are probably okay to ignore
-- competition?

create or replace view refineries.potential_location as 
select c.qid,c.connected,f.populated,f.terminal,f.epa,f.biopower,f.ethanol
from has_connected c join 
( select qid,populated,terminal,epa,biopower,ethanol 
from  has_populated 
full outer join has_terminal using (qid)
full outer join has_epa using (qid)
full outer join has_biopower using (qid)
full outer join has_ethanol using (qid) ) as f using (qid);

-- There are still some that are within 50km, but that's because some potential locations are not so.
drop table if exists m_potential_location;
create table m_potential_location 
as select c.gid,c.centroid,p.* 
from network.place c join potential_location p using (qid);

alter table m_potential_location add constraint m_potential_location_pk primary key(gid);
create index m_potential_location_centroid_gist on m_potential_location using gist(centroid gist_geometry_ops);
create index m_potential_location_centroid on m_potential_location(centroid);
create index m_potential_location_qid on m_potential_location(qid);

-- Proxy locations basically just remove those that are next to each other.
drop table if exists proxy_location;
\set proxy_distance 50000
--create or replace view  proxy_location as 
create table  proxy_location as 
select distinct p1.qid as src_qid,p2.qid as proxy_qid,
                c2.pop_2000-c1.pop_2000 as pop_diff
from m_potential_location p1 
join network.place c1 using (qid),
m_potential_location p2 
join network.place c2 using (qid) 
where p1.qid=p2.qid or  
      ( ST_Dwithin(c1.centroid,c2.centroid,:proxy_distance)
        and (    c1.pop_2000 < c2.pop_2000 
             or (c1.pop_2000=c2.pop_2000 and c1.centroid < c2.centroid)));

delete from proxy_location c 
where pop_diff != (select max(pop_diff) from proxy_location 
                    where src_qid=c.src_qid);

delete from proxy_location c 
where pop_diff = 0 and src_qid <> proxy_qid;

create index proxy_location_src_qid on proxy_location(src_qid);
create index proxy_location_proxy_qid on proxy_location(proxy_qid);

drop table if exists m_proxy_location;
create table m_proxy_location as 
select c.name,p.* 
from network.place c 
join (select distinct proxy_qid as qid from proxy_location ) as x using (qid) 
join m_potential_location p using (qid);

alter table m_proxy_location add constraint m_proxy_location_pk primary key(gid);
create index m_proxy_location_centroid on m_proxy_location(centroid);
