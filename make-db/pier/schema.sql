SET search_path = pier, pg_catalog;

DROP TABLE IF EXISTS landcover_class ;
CREATE TABLE landcover_class (
 class char(2),
 subclass char(2),
 name varchar(256),
 description text
);

COPY landcover_class (class,subclass,name,description) from STDIN delimiter as '|';
G|**|GRAIN AND HAY CROPS|
G|1|Barley|
G|2|Wheat|
G|3|Oats|
G|6|Miscellaneous and mixed grain and hay|
R|**|RICE|
F|**|FIELD CROPS|
F|1|Cotton|
F|2|Safflower|
F|3|Flax|
F|4|Hops|
F|5|Sugar beets|
F|6|Corn (field & sweet)|
F|7|Grain sorghum|
F|8|Sudan|
F|9|Castor beans|
F|10|Beans (dry)|
F|11|Miscellaneous field|
F|12|Sunflowers|
P|**|PASTURE|
P|1|Alfalfa & alfalfa mixtures|
P|2|Clover native pasture|
P|3|Mixed pasture|
P|4|Native Pasture|
P|5|Induced high water table|
P|6|Misc. grasses (normally grown for seed)|
P|7|Turf farms|
T|**|TRUCK, NURSERY AND BERRY CROPS|
T|1|Artichokes|
T|2|Asparagus|
T|3|Beans (green)|
T|4|Cole crops (when further breakdown is not needed)|
T|6|Carrots|
T|7|Celery|
T|8|Lettuce (all types)|
T|9|Melons, squash, and cucumbers (all types)|
T|10|Onions and garlic|
T|11|Peas|
T|12|Potatoes|
T|13|Sweet Potatoes|
T|14|Spinach|
T|15|Tomatoes|
T|16|Flowers, nursery & Christmas tree farms|
T|17|Mixed (four or more)|
T|18|Miscellaneous truck|
T|19|Bush berries|
T|20|Strawberries|
T|21|Peppers (chili, bell, etc.)|
T|22|Broccoli|
T|23|Cabbage|
T|24|Cauliflower|
T|25|Brussels sprouts|
D|**|DECIDUOUS FRUITS AND NUTS|
D|1|Apples|
D|2|Apricots|
D|3|Cherries deciduous|
D|5|Peaches and nectarines|
D|6|Pears|
D|7|Plums|
D|8|Prunes|
D|9|Figs|
D|10|Miscellaneous|
D|12|Almonds|
D|13|Walnuts|
D|14|Pistachios|
C|CITRUS AND SUBTROPICAL|
C|1|Grapefruit|
C|2|Lemons subtropical fruits|
C|3|Oranges|
C|4|Dates|
C|5|Avocados|
C|6|Olives|
C|7|Miscellaneous|
C|8|Kiwis|
C|9|Jojoba|
C|10|Eucalyptus|
V|**|VINEYARDS|
V|1|Table grapes|
V|2|Wine grapes|
V|3|Raisin grapes|
I|IDLE|(Precede with "n" in non-irrigated area, and must include subclass)|
I|1|Land not cropped the current or previous crop season, but cropped within the past three years.|
I|2|New lands being prepared for crop production.|
S|**|SEMIAGRICULTURAL & INCIDENTAL TO AGRICULTURE|(Must include subclass)
S|1|Farmsteads|
S|2|Livestock feed lots|
S|3|Dairies|
S|4|Poultry farms|
U|URBAN|Residential, commercial, and industrial (may be used alone when further breakdown is not required)|
UR|RESIDENTIAL|Single and multiple family units, including trailer courts (may be used alone when further breakdown is not required).|
UR|11|Single family dwellings with lot sizes greater than 1 acre up to 5 acres (ranchettes, etc.), 0% to 25% area irrigated|
UR|21|Single family dwellings with a density of 1 unit/acre up to 8+ units/acre. 0% to 25% area irrigated|
UR|31|Multiple family (apartments, condos, townhouses, barracks, bungalows, duplexes,etc.) 0% to 25% area irrigated|
UR|41|Trailer courts, 0% to 25% area irrigated|
UR|12|Single family dwellings with lot sizes greater than 1 acre up to 5 acres (ranchettes, etc.) 26% to 50% area irrigated|
UR|22|Single family dwellings with a density of 1 unit/acre up to 8+ units/acre. 26% to 50% area irrigated|
UR|32|Multiple family (apartments, condos, townhouses, barracks, bungalows, duplexes,etc.) 26% to 50% area irrigated|
UR|42|Trailer courts 26% to 50% area irrigated|
UR|13|Single family dwellings with lot sizes greater than 1 acre up to 5 acres (ranchettes, etc.) 51% to 75% area irrigated|
UR|23|Single family dwellings with a density of 1 unit/acre up to 8+ units/acre. 51% to 75% area irrigated|
UR|33|Multiple family (apartments, condos, townhouses, barracks, bungalows, duplexes,etc.) 51% to 75% area irrigated|
UR|43|Trailer courts 51% to 75% area irrigated|
UR|14|Single family dwellings with lot sizes greater than 1 acre up to 5 acres (ranchettes, etc.) 76% or greater|
UR|24|Single family dwellings with a density of 1 unit/acre up to 8+ units/acre. 76% or greater|
UR|34|Multiple family (apartments, condos, townhouses, barracks, bungalows, duplexes,etc.) 76% or greater|
UR|44|Trailer courts 76% or greater|
UC|**|COMMERCIAL|(May be used alone when further breakdown is not required)|
UC|1|Offices, retailers, etc.|
UC|2|Hotels|
UC|3|Motels|
UC|4|Recreation vehicle parking, camp sites|
UC|5|Institutions (hospitals, prisons, reformatories, asylums, etc., having a reasonably constant 24-hour resident population)|
UC|6|Schools (yards to be mapped separately if large enough)|
UC|7|Municipal auditoriums, theaters, churches, buildings and stands associated with race tracks, football stadiums, baseball parks, rodeo arenas, amusement parks, etc.|
UC|8|Miscellaneous high water use (to be used to indicate a high water use condition not covered by the above categories.)|
UI|**|INDUSTRIAL|(May be used alone when further breakdown is not required)|
UC|1|Manufacturing, assembling, and general processing|
UC|2|Extractive industries (oil fields, rock quarries, gravel pits, rock and gravel processing plants, etc.)|
UC|3|Storage and distribution (warehouses, substations, railroad marshalling yards, tank farms, etc.)|
UC|6|Saw mills|
UC|7|Oil refineries|
UC|8|Paper mills|
UC|9|Meat packing plants|
UC|10|Steel and aluminum mills|
UC|11|Fruit and vegetable canneries and general food processing|
UC|12|Miscellaneous high water use (to be used to indicate a high water use condition not covered by other categories.)|
UC|13|Sewage treatment plant including ponds.|
UC|14|Waste accumulation sites (public dumps, sewage sludge sites, landfill and hazardous waste sites, etc.)|
UC|15|Wind farms, solar collector farms, etc.|
UL|URBAN LANDSCAPE|(May be used alone when further breakdown is not required)|
UL|1|Lawn area - irrigated|
UL|2|Golf course - irrigated|
UL|3|Ornamental landscape (excluding lawns) - irrigated|
UL|4|Cemeteries - irrigated|
UL|5|Cemeteries - not irrigated|
UV|**|VACANT|(May be used alone when further breakdown is not required)|
UV|1|Unpaved areas (vacant lots, graveled surfaces, play yards, developable open lands within urban areas, etc.)|
UV|3|Railroad right of way.|
UV|4|Paved areas (parking lots, paved roads, oiled surfaces, flood control channels, tennis court areas, auto sales lots, etc.)|
UV|6|Airport runways|
NC|**|NATIVE CLASSES UNSEGREGATED|(May be used alone when further breakdown is not required)|
NV|**|NATIVE VEGETATION|(May be used alone when further breakdown is not required)|
NV|1|Grass land|
NV|2|Light brush|
NV|3|Medium brush|
NV|4|Heavy brush|
NV|5|Brush and timber|
NV|6|Forest|
NV|7|Oak grass land|
NR|**|RIPARIAN VEGETATION|(May be used alone when further breakdown is not required)|
NR|1|Marsh lands, tules and sedges|
NR|2|Natural high water table meadow|
NR|3|Trees, shrubs or other larger stream side or watercourse vegetation|
NR|4|Seasonal duck marsh, dry or only partially wet during summer|
NR|5|Permanent duck marsh, flooded during summer|
NW|**|WATER SURFACE|Lakes, reservoirs, rivers, canals, etc.|
NB|**|BARREN AND WASTELAND|(May be used alone when further breakdown is not required)|
NB|1|Dry stream channels|
NB|2|Mine Tailing|
NB|3|Barren land|
NB|4|Salt flats|
NB|5|Sand dunes|
NS|**|NOT SURVEYED|Area within the investigation area that was not mapped.|
E|**|ENTRY DENIED|Area within the investigation area that was not mapped because entry into the area was denied.|
Z|**|OUTSIDE|Area outside of the study area.|