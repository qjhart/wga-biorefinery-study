\set qr '''REGION'''
\set r REGION
\set travel_cost_per_bdt 25

drop schema if exists :r cascade;
create schema :r;
set search_path=:r,public;

create table source_list as 
select * from model.model_source_list(:travel_cost_per_bdt,:qr,'lce');
create table price as 
select * from model.model_price(:travel_cost_per_bdt,:qr,'lce');
create table supply as 
select * from model.model_supply(:travel_cost_per_bdt,:qr,'lce');
create table src2refine as 
select * from model.model_src2refine(:travel_cost_per_bdt,:qr,'lce');
create table src2refine_liq as 
select * from model.model_src2refine_liq(:travel_cost_per_bdt,:qr,'lce');
create table terminal_odcosts as 
select * from model.model_terminal_odcosts(:travel_cost_per_bdt,:qr,'lce');
create table refine as 
select * from model.model_refine(:qr,'lce');

create table pulpmills as 
select qid,cap_2000,sulfit2000,sulfat2000 
from forest.pulpmills 
join model.region_states 
on(substring(qid from 2 for 2)=state_fips) and region=:qr;
