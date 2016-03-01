#! /usr/bin/make -f

# States.
${out}/states.csv:
	${PG-CSV} - 'select state,state_fips as ansi,state_abbrev as alpha_code from network.state order by state_fips' >$@

${out}/state.json:${db}/network.state
	echo '{' > $@;
	${PG} -A -F',' --pset footer -t -q -c "select '\"'||state_fips||'\":{\\n \"longitude\" :'||x(transform(centroid(boundary),4269))||',\\n \"latitude\" :'||y(transform(centroid(boundary),4269))||',\\n \"border\" : \"'||asKML(2,transform(simplify(boundary,5000),4269),6)||'\"\\n},' from network.state" >>$@
	echo '}' >> $@;
