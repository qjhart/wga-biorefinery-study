\set ON_ERROR_STOP 1
BEGIN;
SET search_path = ca_facilities, public;

drop table if exists swis cascade;
-- "SwisNo","UnitNo","SiteName",CountyID,"County","Operator","Location","PlaceName","Zip","EnforAgent","Owner","Category","Activity","RegStatus","OpStatus",Latitude,Longitude,SiteID,UnitID
CREATE TABLE swis (
gid serial primary key,
swisno varchar(12),
unitno varchar(2),
sitename varchar(256),
state char(2),
countyid integer,
county varchar(32),
operator varchar(256),
location varchar(256),
placename varchar(256),
zip varchar(10),
enforangent varchar(256),
owner varchar(256),
category varchar(128),
activity varchar(128),
regstatus varchar(128),
opstatus varchar(32),
latitude float,
longitude float,
latlon varchar(256),
siteid integer,
unitid integer
);

COPY swis (swisno,unitno,sitename,countyid,county,operator,location,placename,
zip,enforangent,owner,category,activity,regstatus,opstatus,latitude,longitude,siteid,unitid)
FROM 'swis.csv' WITH DELIMITER AS ',' QUOTE AS '"' CSV HEADER;

update swis set 
swisno=trim(both from swisno),
unitno=trim(both from unitno),
sitename=trim(both from sitename),
county=trim(both from county),
operator=trim(both from operator),
location=trim(both from location),
placename=trim(both from placename),
zip=trim(both from zip),
enforangent=trim(both from enforangent),
owner=trim(both from owner),
category=trim(both from category),
activity=trim(both from activity),
regstatus=trim(both from regstatus),
opstatus=trim(both from opstatus),
state='CA';

select addGeometryColumn('ca_facilities','swis','centroid',3310,'POINT',2);
update swis set centroid=transform(setsrid(makepoint(longitude,latitude),4269),3310);
select add_qid('ca_facilities','swis','state','placename');

\echo The following places lack qids
select swisno from swis where qid is null;

create view swis_fusion as 
select swisno,unitno,sitename,state,county,operator,
 location||','||placename||',CA '||zip as address,zip,
 enforangent,owner,category,activity,regstatus,opstatus,siteid,unitid,qid,
 latitude||','||longitude as location from 
ca_facilities.swis;

END;
