#!/usr/bin/env python
import mapnik, os
rootdir = '/home/peter/Documents/DOE/bioenergy/make-db/trunk/results'
os.chdir(rootdir)
mapfile = rootdir + '/src/fs_links.xml'
map_output = rootdir + '/out/fs_links.png'
m = mapnik.Map(1200, 1200)
mapnik.load_map(m, mapfile)
#bbox = mapnik.Envelope(mapnik.Coord(-180.0, -90.0), mapnik.Coord(180.0, 90.0))
bbox = mapnik.Envelope(mapnik.Coord(-2327043.5, -1291466), mapnik.Coord(2253634.75,1278301.125))
m.zoom_to_box(bbox) 
mapnik.render_to_file(m, map_output)
