set search_path=model,public;

create table fpr_mini (
fpr_id integer primary key,
us_region varchar(10)
);

COPY fpr_mini (fpr_id,us_region) from STDIN WITH CSV HEADER;
 fpr_id,us_region
1,east
2,corn
3,south
4,north
5,west
7,east
8,north
9,west
10,east
11,south
\.
