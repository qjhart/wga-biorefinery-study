BEGIN;
set search_path=public;

CREATE OR REPLACE FUNCTION add_nad83(schemaname varchar(32), tablename varchar(32), longitude varchar(32), latitude varchar(32),OUT count integer)
AS $$
DECLARE
t varchar;
BEGIN
t=quote_ident(schemaname) || '.' || quote_ident(tablename);
perform addGeometryColumn(schemaname,tablename,'nad83',4269,'POINT',2);
EXECUTE 'UPDATE ' || t || ' set nad83=setsrid(MakePoint( ' || quote_ident(longitude) ||',' || quote_ident(latitude) || '),4269)';
END;
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION add_centroid(schemaname varchar(32), tablename varchar(32),out count integer)
AS $$
DECLARE
t varchar;
BEGIN
t=quote_ident(schemaname) || '.' || quote_ident(tablename);
PERFORM addGeometryColumn(schemaname,tablename,'centroid',102004,'POINT',2);
EXECUTE 'UPDATE ' || quote_ident(schemaname) || '.' || quote_ident(tablename) || ' set centroid=transform(nad83,102004);';
EXECUTE 'CREATE INDEX "'||quote_ident(tablename)||'_centroid_gist" ON '|| t ||' using gist ("centroid" gist_geometry_ops)';
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION 
add_qid(schemaname varchar(32), tablename varchar(32),state_fips char(2),
        name varchar(255),OUT count integer)
AS $$
DECLARE
t varchar;
BEGIN
	t=quote_ident(schemaname) || '.' || quote_ident(tablename);
	EXECUTE 'alter table ' || t || ' add qid char(8)';
	EXECUTE 'update '|| t || ' f set qid=cx.qid from network.place cx where f.'||
                state_fips||'=cx.state and lower(f.'||name||')=lower(cx.name)';
	EXECUTE 'update '|| t || ' f set qid=ul.qid from 
	( select cx.qid,ul.gid from network.place cx join
	  ( select l.gid,transform(l.centroid,102004) as centroid,
            min(distance(transform(l.centroid,102004),c.centroid)) as min 
            from (select gid,'||state_fips||',centroid from '|| t ||' where qid is null ) as l,
                  network.place c where c.state=l.'||state_fips||' group by l.gid,l.centroid ) as ul
	  on (distance(cx.centroid,ul.centroid)=ul.min) 
	) as ul where f.gid=ul.gid';
END;
$$ LANGUAGE 'plpgsql';

END;


