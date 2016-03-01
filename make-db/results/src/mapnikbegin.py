#!/usr/bin/env python

import mapnik, os
os.chdir('/home/peter/Documents/DOE/')



# Instantiate a map object with given width, height and spatial reference system
m = mapnik.Map(600,300,"+init=esri:102004")
# Set background colour to 'steelblue'.  
# You can use 'named' colours, #rrggbb, #rgb or rgb(r%,g%,b%) format
m.background = mapnik.Color('steelblue')

# Now lets create a style and add it to the Map.
s = mapnik.Style()
# A Style can have one or more rules. A rule consists of a filter, min/max scale 
# demoninators and 1..N Symbolizers. If you don't specify filter and scale denominators
# you get default values :
#   Filter =  'ALL' filter (meaning symbolizer(s) will be applied to all features) 
#   MinScaleDenominator = 0
#   MaxScaleDenominator = INF  
# Lets keep things simple and use default value, but to create a map we 
# we still must provide at least one Symbolizer. Here we  want to fill countries polygons with 
# greyish colour and draw outlines with a bit darker stroke. 

r=mapnik.Rule()
r.symbols.append(mapnik.PointSymbolizer(mapnik.Color('rgb(50%,50%,50%)'),0.1))
#r.symbols.append(mapnik.LineSymbolizer(mapnik.Color('rgb(50%,50%,50%)'),0.1))
s.rules.append(r)

# Here we have to add our style to the Map, giving it a name.
m.append_style('My Style',s)

# Here we instantiate our data layer, first by giving it a name and srs (proj4 projections string), and then by giving it a datasource.
#lyr = mapnik.Layer('test',"+int=epsg:102004")
# Then provide the full filesystem path to a shapefile in WGS84 or EPSG 4326 projection without the .shp extension
# A sample shapefile can be downloaded from http://mapnik-utils.googlecode.com/svn/data/world_borders.zip
lyr = mapnik.Layer('Geometry from PostGIS',"+init=esri:102004")
lyr.datasource = mapnik.PostGIS(dbname='geo',table='r_baseline.brfn_locations')
#(host='localhost',user='postgres',password='postgres',dbname='geo',table='r_baseline.brfn_locations')
#lyr.datasource = mapnik.Shapefile(file='/home/peter/Documents/DOE/world_borders/world_borders')
#lyr.styles.append('My Style')

m.layers.append(lyr)
m.zoom_to_box(lyr.envelope())

# Write the data to a png image called world.png in the base directory of your user
mapnik.render_to_file(m,'test.png', 'png')

# Exit the python interpreter
exit()