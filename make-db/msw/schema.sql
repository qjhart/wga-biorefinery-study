drop SCHEMA IF exists msw CASCADE;
CREATE SCHEMA msw;
SET search_path = msw, pg_catalog;
SET default_with_oids = false;


CREATE TABLE state (
       state varchar(25) primary key,
       pop2006 integer,
       msw_generate_tons_yr float,
       msw_recycled_tons_yr float,
       msw_wte_tons_yr float,
       msw_landfilled_tons_yr float
);
COPY state FROM STDIN;
Alabama	4590240	6996343	591608	194039	6210696
Alaska	677450	765354	28646	3000	733708
Arizona	6165689	8197591	1025591	0	7172000
Arkansas	2809111	3468842	532689	35464	2900689
California	36249872	49926000	19409000	591000	29926000
Colorado	4766248	8690005	481598	0	8208407
Connecticut	3495753	3360933	830264	2158292	372377
Delaware	852747	988433	103150	0	885283
District of Columbia	585459	1031083	21142	12791	997150
Florida	18057508	23631947	6775329	5796339	11060279
Georgia	9342080	11549889	0	81535	7195075
Hawaii	1278635	1649000	410000	756000	483000
Idaho	1463878	1238394	99590	0	1138804
Illinois	12777042	26420364	9773194	0	16647170
Indiana	6302646	13570231	4531056	569263	8469912
Iowa	2972566	4341454	1464395	54496	2822563
Kansas	2755817	4089591	817818	0	3271773
Kentucky	4204444	7887748	2996565	63700	4827483
Louisiana	4243288	6051158	500000	0	5551158
Maine	1314910	2178339	695580	701811	780948
Maryland	5602017	7009905	2536633	1371970	3101302
Massachusetts	6434389	9160000	3410000	3100000	2650000
Michigan	10102322	12768089	2594940	1039389	9133760
Minnesota	5154586	5894933	2523635	1170841	2200457
Mississippi	2899112	3194368	145000	0	3049368
Missouri	5837639	9939008	3183864	23300	6731844
Montana	946795	1430049	240510	0	1189539
Nebraska	1763765	2360861	260514	0	2100347
Nevada	2492427	3007000	619000	0	2388000
New Hampshire	1311821	1269774	406693	206873	656208
New Jersey	8666075	12756058	4400000	1397094	6958964
New Mexico	1942302	2125052	191601	0	1933451
New York	19281988	21686509	7694160	3491700	10500649
North Carolina	8869442	8205475	1877277	107837	6220361
North Dakota	637460	660552	83404	0	577148
Ohio	11463513	16885677	3530328	0	13355349
Oklahoma	3577536	4394393	170000	0	4224393
Oregon	3691084	4426431	1820063	203103	2403265
Pennsylvania	12402817	16486254	4868115	1951447	9666692
Rhode Island	1061641	1351454	166962	1995	1182497
South Carolina	4330108	4974679	1510409	224506	3239764
South Dakota	788467	861576	83476	0	778100
Tennessee	6074913	1211686	4798402	0	7413284
Texas	23407629	31212927	5900000	0	25312927
Utah	2579535	2864492	438873	123912	2301707
Vermont	620778	644226	229953	47286	366987
Virginia	7640249	12210991	4140457	2135407	5935127
Washington	6374910	8313340	2725310	325298	5262632
West Virginia	1808699	2110381	337661	0	1772270
Wisconsin	5617744	5881023	1886545	454321	3540157
Wyoming	512757	684690	73200	0	611490
\.

alter table msw.state add column stfips varchar(2);
update msw.state m set stfips=s.state_fips from network.state s where m.state=s.state;

-- View of percentages
\set StateMax 50000

create or replace view msw.major_city_percentages as 
select gid,qid,fips55,name,stfips,1.0*c.pop_2000/sum as frac,s.state_max 
from network.place c join 
(select stfips,count(*),sum(pop_2000) as sum,max.state_max 
 from network.place 
 join 
  (select stfips,
   CASE WHEN (max(pop_2000) > :StateMax) 
      THEN :StateMax 
      ELSE max(pop_2000) END as state_max 
   from network.place 
   group by stfips) as max 
using (stfips) 
where pop_2000 >= max.state_max 
group by stfips,state_max 
order by stfips) as s 
using (stfips) 
where c.pop_2000 >= s.state_max;

create or replace view msw.msw_by_city as 
select gid,qid,fips55,name,
 frac*msw_generate_tons_yr as msw_generate_tons_yr,
 frac*msw_recycled_tons_yr as msw_recycled_tons_yr,
 frac*msw_wte_tons_yr as msw_wte_tons_yr,
 frac*msw_landfilled_tons_yr as msw_landfilled_tons_yr 
from msw.state 
join msw.major_city_percentages 
using (stfips);
