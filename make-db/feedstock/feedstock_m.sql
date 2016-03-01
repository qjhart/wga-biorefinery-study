SET search_path = feedstock, public;
\set ON_ERROR_STOP 1
BEGIN;
drop table if exists feedstock_m;
create table feedstock_m (
    fid serial,
    qid varchar(8),
    type varchar(24),
    marginal_addition float,
    price float);

insert into feedstock_m (qid,type,marginal_addition,price) 
select qid,type,marginal_addition,
       replace(substr(price_id,3,10),'_','.')::float as price
from feedstock.feedstock;

create index feedstock_m_qid on feedstock.feedstock_m(qid);
create index feedstock_m_type on feedstock.feedstock_m(type);

END;