SET search_path = ssurgo, pg_catalog;
drop table if exists mucropyld CASCADE;
create table mucropyld (
 uid serial primary key,
 cropname varchar(254) references crop_name(cropname),
 yldunits varchar(254) references crop_yield_units(yldunits),
nonirryield_l decimal(7,2),
nonirryield_r decimal(7,2),
nonirryield_h decimal(7,2),
irryield_l decimal(7,2),
irryield_r decimal(7,2),
irryield_h decimal(7,2),
mukey varchar(30) not null,
mucrpyldkey varchar(30) unique
);

create view crop_yld_by_mu as 
       select c.uid,mukey,cropname,yldunits,nonirryield_r,irryield_r,m.boundary		from mucropyld c left join map_unit m using (mukey);

