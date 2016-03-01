\set s ncp_@SCENARIO@
\set qs '''ncp_@SCENARIO@'''

set search_path=:s,public;

create or replace function summary_chart(t brfn) 
returns TEXT AS $$
DECLARE
total float;
nmes text;
vals text;
BEGIN
total=t.ag_res+t.hec+t.forest+t.ovw+t.pulpwood+t.msw_wood+t.msw_paper
     +t.msw_constr_demo+t.msw_yard+t.msw_food+t.msw_dirty+t.corngrain
     +t.animal_fats+t.grease+t.seed_oils+t.sugar;
if (t.type = 'dry_mill' or t.type = 'wet_mill') THEN
nmes='corngrain';
vals=coalesce(t.corngrain,0);
elsif (t.type='sugar_etoh') THEN
nmes='sugar';
vals=coalesce(t.sugar,0);
elsif (t.type='fahc' or t.type='fame') THEN
nmes='animal_fats|grease|seed_oils';
vals=coalesce(t.animal_fats,0)||','||coalesce(t.grease,0)||','||coalesce(t.seed_oils,0);
else
nmes='ag_res|hec|forest|ovw|pulpwood|msw_wood|msw_paper|msw_constr_demo|msw_yard|msw_food|msw_dirty';
vals=coalesce(t.ag_res,0)||','||coalesce(t.hec,0)||','||coalesce(t.forest,0)||','||coalesce(t.ovw,0)||','||coalesce(t.pulpwood,0)||','||coalesce(t.msw_wood,0)||','||coalesce(t.msw_paper,0)||','||coalesce(t.msw_constr_demo,0)||','||coalesce(t.msw_yard,0)||','||coalesce(t.msw_food,0)||','||coalesce(t.msw_dirty,0);
end if;

RETURN 'http://chart.apis.google.com/chart?chxs=0,676767,13&chxt=x&chs=300x225&cht=p&chco=008000,3399CC,FFFF88'||
       '&chds=0,'||total||
       '&chd=t:'|| vals ||
'&chdlp=l&chl='|| names ||'&chma=5,5,5,5&chtt=Feedstocks';
END;
$$ LANGUAGE plpgsql;


