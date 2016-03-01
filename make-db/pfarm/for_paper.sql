create table pfarm.pfarm_cost (
pfarm_gid integer,
dest_id integer,
fips char(5),
actual_nonirr_yield float,
bdt float,
arable_acres float,
windrowing float,
baling float,
roadsiding float,
wrapping float,
rent float,
insurance float,
total_farmgate float,
travel float,
loading float,
unloading float,
total float
);

COPY pfarm.pfarm_cost (pfarm_gid,dest_id,fips,actual_nonirr_yield,bdt,
arable_acres,windrowing,baling,
roadsiding,wrapping,rent,insurance,
total_farmgate,travel,loading,unloading,total) from '/home/quinn/farm_cost.csv' with CSV HEADERS;

-- Okay fix up our network.
insert into network.vertex (point) select centroid from network.place left join network.vertex v on (centroid=point) where name in ('Raymond','Maynard','Palo','Stanwood') and stfips='19' and v is null; 
-- Add in the city connectors
insert into network.edge (type,source,target,segment,miles,bale_cost,liquid_cost)
select 'ref_road' as type,
       s.id as source,d.id as target,
       makeline(s.point,d.point) as segment,
       length(makeline(s.point,d.point))/1609.344 as miles,
       (inl.loading_cost('bale',c.fips,2010)).unloading as bale_cost,
       (inl.loading_cost('liquid',c.fips,2010)).unloading as liquid_cost
  from
  network.place p
  join network.place_roads cr on (p.gid=cr.p_gid)
  join network.vertex s on (p.centroid=s.point) 
  join network.vertex d on (cr.centroid=d.point)
  join network.county c on (ST_within(s.point,c.boundary))
  where p.name in ('Raymond','Maynard','Palo','Stanwood') and p.stfips='19'; 

-- Now we can calculate the shortest paths.
create temp table for_paper as
select src,dest,sum(cost) from (
 select s.src,s.dest,
       (shortest_path('select id,source,target,coalesce(bale_cost,0) as cost from network.edge'::text,
        s.src,s.dest,false,false)).cost 
 from (
select s.id as src,d.id as dest 
from 
network.place p join network.vertex s on (centroid=point) ,
network.vertex d join network.county c on (point=centroid)      
where p.name in ('Raymond','Maynard','Palo','Stanwood') and p.stfips='19' 
and c.fips in ('19011','19013','19019','19031','19055','19065','19105','19113')
) as s
) as paths 
group by src,dest;

-- 

select c.name,p.name,min::decimal(10,2) as to_city, 
inl.travel_cost('bale',c.fips,2010,(perimeter(c.boundary)/8/1609.344),
                (perimeter(c.boundary)/8/1609.344/35))::decimal(10,2) as interior 
from (
 select src,dest,sum,min(sum) over w as min 
 from for_paper 
 window w as (partition by dest)) as min 
join network.vertex d on (d.id=dest) 
join network.county c on (c.centroid=d.point) 
join network.vertex s on (s.id=src) 
join network.place p on (p.centroid=s.point) 
where sum=min;

--        name        |   name   |       min        |     interior     
-- -------------------+----------+------------------+------------------
--  Linn County       | Palo     | 6.99248355010784 | 2.59879375026098
--  Cedar County      | Stanwood | 5.07694765553918 | 2.31747633272593
--  Benton County     | Palo     |   8.151932663804 |  2.6018985222698
--  Fayette County    | Maynard  | 4.64379043840341 | 2.62566460483963
--  Black Hawk County | Raymond  | 4.67888372710453 | 2.34251020103207
--  Buchanan County   | Raymond  | 6.68699641707713 | 2.34352132246544
--  Delaware County   | Maynard  | 10.8571442433696 | 2.32987551338079
--  Jones County      | Stanwood | 6.01331771002804 |  2.3045045710158
