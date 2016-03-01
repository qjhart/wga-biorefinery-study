drop SCHEMA IF exists nass CASCADE;
CREATE SCHEMA nass;
SET search_path = nass, pg_catalog;
SET default_with_oids = false;

CREATE TABLE nass (
    fips varchar(5),
    district character varying(6),
    "year" integer,
    commcode integer,
    praccode integer,
    planted integer,
    pltdHarv integer,
    harvested integer,
    pltdYield float,
    yield double precision,
    yieldunit character varying(32),
    production int8,
    productionunit character varying(32),
    sucrose integer,
    sucroseunit character varying(32),
    primary key (fips,district,"year",commcode,praccode)
);

create table farm_production_regions (
fips varchar(2),
state varchar(32),
region varchar(32)
);

COPY farm_production_regions (state,region) FROM STDIN DELIMITER AS ',' NULL AS '';
Alabama,Southeast
Alaska,Pacific
Arizona,Mountain
Arkansas,Delta States
California,Pacific
Colorado,Mountain
Connecticut,Northeast
Delaware,Northeast
District of Columbia,
Florida,Southeast
Georgia,Southeast
Hawaii,Pacific
Idaho,Mountain
Illinois,Corn Belt
Indiana,Corn Belt
Iowa,Corn Belt
Kansas,Northern Plains
Kentucky,Appalachia
Louisiana,Delta States
Maine,Northeast
Maryland,Northeast
Massachusetts,Northeast
Michigan,Lake States
Minnesota,Lake States
Mississippi,Delta States
Missouri,Corn Belt
Montana,Mountain
Nebraska,Northern Plains
Nevada,Mountain
New Hampshire,Northeast
New Jersey,Northeast
New Mexico,Mountain
New York,Northeast
North Carolina,Appalachia
North Dakota,Northern Plains
Ohio,Corn Belt
Oklahoma,Southern Plains
Oregon,Pacific
Pennsylvania,Northeast
Rhode Island,Northeast
South Carolina,Southeast
South Dakota,Northern Plains
Tennessee,Appalachia
Texas,Southern Plains
Utah,Mountain
Vermont,Northeast
Virginia,Appalachia
Washington,Pacific
West Virginia,Appalachia
Wisconsin,Lake States
Wyoming,Mountain
\.


CREATE TABLE commodity (
    commcode integer primary key,
    commodity_description character varying(255),
    commodity_description2 character varying(255)
);

CREATE TABLE district (
    district character varying(4) primary key
);

CREATE TABLE practice (
    praccode integer primary key,
    practice character varying(128)
);
COPY practice (praccode,practice) FROM STDIN;
1	Irrigated
2	Non Irrigated Total
3	Non Irrigated: Following Summer Fallow
4	Non Irrigated: Continuous Cropping
9	Total For Crop
\.

CREATE TABLE units (
    unit character varying(32) primary key
);


-- 
-- taken from  http://www.nass.usda.gov/Data_and_Statistics/County_Data_Files/Frequently_Asked_Questions/commcodes.html
--
COPY commodity (commcode, commodity_description, commodity_description2) FROM stdin;
8199999	Crop Farms	Farm Crop Farms
8499999	Livestock Farms	Farm Livestock Farms
8991099	Sales Less than $10,000	Farm Sales Less than $10,000
8992099	Sales $10,000 to $39,999	Farm Sales $10,000 to $39,999
8993099	Sales $40,000 to $99,999	Farm Sales $40,000 to $99,999
8994099	Sales $100,000 to $249,999	Farm Sales $100,000 to $249,999
8995099	Sales $250,000 +	Farm Sales $250,000 +
8999999	All Farms	Farm All Farms
10111999	Wheat Winter Hard Red	Wheat Winter Hard Red
10112999	Wheat Winter Soft Red	Wheat Winter Soft Red
10113999	Wheat Winter White	Wheat Winter White
10119999	Wheat Winter All	Wheat Winter All
10129999	Wheat Durum	Wheat Durum
10131999	Wheat Spring Hard Red	Wheat Spring Hard Red
10133999	Wheat Spring White	Wheat Spring White
10139999	Wheat Other Spring	Wheat Other Spring
10191999	Wheat Hard Red All	Wheat Hard Red All
10193999	Wheat White All	Wheat White All
10199999	Wheat All	Wheat All
10499999	Rye	Rye
10611999	Rice Long Grain	Rice Long Grain
10612999	Rice Med Grain	Rice Medium Grain
10613999	Rice Short Grain	Rice Short Grain
10614999	Rice Med-Short Grain	Rice Medium-Short Grain
10619999	Rice All	Rice All
11199199	Corn For Grain	Corn For Grain
11199299	Corn For Silage	Corn For Silage
11199999	Corn All	Corn All
11299999	Oats	Oats
11399499	Barley Malting	Barley Malting
11399599	Barley Feed	Barley Feed
11399999	Barley All	Barley All
11499199	Sorghum For Grain	Sorghum For Grain
11499299	Sorghum For Silage	Sorghum For Silage
11499999	Sorghum All	Sorghum All
11869999	Millet (Proso)	Millet (Proso)
11889999	Capacity Storage	Capacity Storage
12121999	Cotton Upland	Cotton Upland
12122999	Cotton Amer. Pima	Cotton American Pima
12129999	Cotton All Lint (Ginned)	Cotton All Lint (Ginned)
13199199	Sugarcane For Sugar	Sugarcane For Sugar
13199299	Sugarcane For Seed	Sugarcane For Seed
13199399	Sugarcane For Sugar And Seed	Sugarcane For Sugar And Seed
13299199	Sugarbeets	Sugarbeets
13399999	Maple Syrup	Maple Syrup
14111199	Tobacco Flue-Cured Old/Mid Belts (Type 11)	Tobacco Flue-Cured Old/Mid Belts (Type 11)
14111299	Tobacco Flue-Cured East NC Belt (Type 12)	Tobacco Flue-Cured East NC Belt (Type 12)
14111399	Tobacco Flue-Cured NC Bord & SC Belt (Type 13)	Tobacco Flue-Cured NC Bord & SC Belt (Type 13)
14111499	Tobacco Flue-Cured Ga-Fla Belt (Type 14)	Tobacco Flue-Cured Ga-Fla Belt (Type 14)
14119999	Tobacco Flue-Cured All (Class 1)	Tobacco Flue-Cured All (Class 1)
14122199	Tobacco Fire-Cured Va Belt (Type 21)	Tobacco Fire-Cured Va Belt (Type 21)
14122299	Tobacco Fire-Cured Eastern District (Type 22)	Tobacco Fire-Cured Eastern District (Type 22)
14122399	Tobacco Fire-Cured Western District (Type 23)	Tobacco Fire-Cured Western District (Type 23)
14122499	Tobacco Fire-Cured Henderson Belt (Type 24)	Tobacco Fire-Cured Henderson Belt (Type 24)
14122999	Tobacco Fire-Cured Ky-Tn (Type 22-23)	Tobacco Fire-Cured Ky-Tn (Type 22-23)
14129999	Tobacco Fire-Cured All (Class 2)	Tobacco Fire-Cured All (Class 2)
14133199	Tobacco Air-Cured Light Burley (Type 31)	Tobacco Air-Cured Light Burley (Type 31)
14133299	Tobacco Air-Cured Light Southern Md Belt (Type 32)	Tobacco Air-Cured Light Southern Md Belt (Type 32)
14133399	Tobacco Air-Cured Light All (Class 3A)	Tobacco Air-Cured Light All (Class 3A)
14133599	Tobacco Air-Cured Dark One-Sucker Belt (Type 35)	Tobacco Air-Cured Dark One-Sucker Belt (Type 35)
14133699	Tobacco Air-Cured Dark Green River Belt (Type 36)	Tobacco Air-Cured Dark Green River Belt (Type 36)
14133799	Tobacco Air-Cured Dark Sun-Cured Belt (Type 37)	Tobacco Air-Cured Dark Sun-Cured Belt (Type 37)
14133999	Tobacco Air-Cured Dark All (Class 3B)	Tobacco Air-Cured Dark All (Class 3B)
14134099	Tobacco Air-Cured Dark Ky-Tn (Type 35-36)	Tobacco Air-Cured Dark Ky-Tn (Type 35-36)
14139999	Tobacco Air-Cured All (Class 3)	Tobacco Air-Cured All (Class 3)
14199999	Tobacco Non-Cigar Types All (Class 1-3)	Tobacco Non-Cigar Types All (Class 1-3)
14244199	Tobacco Cigar Filler Pa Seed Leaf (Type 41)	Tobacco Cigar Filler Pa Seed Leaf (Type 41)
14244299	Tobacco Cigar Filler Ohio-Miami Valley (Type 42-44)	Tobacco Cigar Filler Ohio-Miami Valley (Type 42-44)
14244999	Tobacco Cigar Filler All (Class 4)	Tobacco Cigar Filler All (Class 4)
14255199	Tobacco Cigar Binder Conn Valley Broadleaf (Type 51)	Tobacco Cigar Binder Conn Valley Broadleaf (Type 51)
14255299	Tobacco Cigar Binder Conn Valley Havana Seed (Type 52)	Tobacco Cigar Binder Conn Valley Havana Seed (Type 52)
14255399	Tobacco Cigar Binder Conn Valley (Class 5A)	Tobacco Cigar Binder Conn Valley (Class 5A)
14255499	Tobacco Cigar Binder Southern Wisconsin (Type 54)	Tobacco Cigar Binder Southern Wisconsin (Type 54)
14255599	Tobacco Cigar Binder Northern Wisconsin (Type 55)	Tobacco Cigar Binder Northern Wisconsin (Type 55)
14255999	Tobacco Cigar Binder Wisconsin (Class 5B)	Tobacco Cigar Binder Wisconsin (Class 5B)
14259999	Tobacco Cigar Binder All (Class 5)	Tobacco Cigar Binder All (Class 5)
14266199	Tobacco Cigar Wrapper Conn Valley Shade-Grown (Type 61)	Tobacco Cigar Wrapper Conn Valley Shade-Grown (Type 61)
14266299	Tobacco Cigar Binder Ga-Fl Shade Grown (Type 62)	Tobacco Cigar Binder Ga-Fl Shade Grown (Type 62)
14269999	Tobacco Cigar Wrapper All (Class 6)	Tobacco Cigar Wrapper All (Class 6)
14299999	Tobacco Cigar Types All (Class 4-6)	Tobacco Cigar Types All (Class 4-6)
14877299	Tobacco Misc Domestic Perique (Type 72)	Tobacco Misc. Domestic Perique (Type 72)
14999999	Tobacco All (All Classes)	Tobacco All (All Classes)
15199999	Cotton Seed	Cotton Seed
15299999	Flaxseed	Flaxseed
15399199	Peanuts	Peanuts
15399999	Peanuts All	Peanuts All
15499199	Soybeans	Soybeans
15499999	Soybeans All	Soybeans All
15819999	Mustard	Mustard
15825599	Canola	Canola
15825999	Rapeseed	Rapeseed
15826999	Safflower	Safflower
15831199	Sunflower Seed For Oil	Sunflower Seed For Oil
15831299	Sunflower Seed Non-Oil Use	Sunflower Seed Non-Oil Use
15831999	Sunflower Seed All	Sunflower Seed All
16113199	Beans Large Lima	Beans Large Lima
16113299	Beans Baby Lima	Beans Baby Lima
16119999	Beans-Dry Edible - Lima-All	Beans Lima All
16171199	Beans Navy (Pea/Beans)	Beans Navy (Pea/Beans)
16171299	Beans Great Northern	Beans Great Northern
16171399	Beans Small White	Beans Small White
16171499	Beans-Dry Edible - White - Small Flat	Beans White Small Flat
16171699	Beans Pinto	Beans Pinto
16171799	Beans All Red Kidney	Beans All Red Kidney
16171899	Beans Light Red Kidney	Beans Light Red Kidney
16171999	Beans Dark Red Kidney	Beans Dark Red Kidney
16172199	Beans Pink	Beans Pink
16172299	Beans Small Red	Beans Small Red
16172399	Beans Cranberry	Beans Cranberry
16172599	Beans Black Turtle Soup	Beans Black Turtle Soup
16174199	Beans Blackeye	Beans Blackeye
16174299	Beans Garbanzo	Beans Garbanzo
16174399	Beans Garbanzo (Chick Peas)	Beans Garbanzo (Chick Peas)
16174499	Beans Garbanzo (Large)	Beans Garbanzo (Large)
16179899	Beans Other Dry Edible	Beans Other Dry Edible
16179999	Beans Dry Edible Other Than Lima	Beans Dry Edible Other Than Lima
16199999	Beans All Dry Edible	Beans All Dry Edible
16319999	Peas-Dry Edible - Smooth Green	Peas Smooth Green
16329999	Peas-Dry Edible - Yellow & White	Peas Yellow & White
16381999	Peas Wrinkled Seeds	Peas Wrinkled Seeds
16399999	Peas Dry Edible	Peas All Dry Edible
16599999	Lentils	Lentils
16819999	Peas Austrian Winter	Peas Austrian Winter
18191999	Alfalfa & Alfalfa Mixtures - New Seedings	Hay Alfalfa & Alfalfa Mixtures - New Seedings
18199999	Hay Alfalfa (Dry)	Hay Alfalfa (Dry)
18311999	Hay Sweet Clover	Hay Sweet Clover
18862999	Hay Cowpea	Hay Cowpea
18863999	Hay Soybean	Hay Soybean
18899999	Hay Other (Dry)	Hay Other (Dry)
18999999	Hay All (Dry)	Hay All (Dry)
19199999	Hops	Hops
19499999	Pasture And Range Condition	Pasture And Range Condition
19591999	Forage Alfalfa(Dry Hay+Haylage)	Forage Alfalfa(Dry Hay+Haylage)
19599999	Forage All(Dry Hay+Haylage)	Forage All(Dry Hay+Haylage)
19999999	Field & Misc Crops	Field & Misc Crops
20099999	Citrus	Citrus All
20139999	Oranges (Mid & Navel)	Oranges (Mid & Navel)
20151999	Oranges Valencia	Oranges Valencia
20169999	Oranges All Except Temples	Oranges All Except Temples
20179999	Oranges Temples	Oranges Temples
20211999	Grapefruit White Seedless	Grapefruit White Seedless
20212999	Grapefruit Color Seedless	Grapefruit Color Seedless
20229999	Grapefruit Other	Grapefruit Other
20299999	Grapefruit All	Grapefruit All
20389999	Tangerines	Tangerines
20499999	Lemons	Lemons
20619999	K-Early Citrus	Citrus K-Early Citrus
20679999	Tangelos	Tangelos
21019999	Major Decidious	Fruit Major Decidious
21029999	Misc. Noncitrus	Fruit Misc. Noncitrus
21099999	All Noncitrus	Fruit All Noncitrus
21199999	Apples	Apples
21219999	Freestone Peaches	Peaches Freestone
21239999	Clingstone Peaches	Peaches Clingstone
21299999	Peaches	Peaches All
21319999	Sweet Cherries	Cherries Sweet
21329999	Tart Cherries	Cherries Cherries
21419999	Bartlett Pears	Pears Bartlett
21479999	Other Pears	Pears Other
21499999	All Pears	Pears All
21519999	Plums	Plums
21599999	Prunes & Plums	Prunes & Plums
21619999	Table Grapes	Grapes Table
21629999	Wine Grapes	Grapes Wine
21639999	Raisin Grapes	Grapes Raisin
21649999	Concord Grapes	Grapes Concord
21659999	Niagara Grapes	Grapes Niagara
21699999	All Grapes	Grapes All
21799999	Apricots	Apricots
21819999	Nectarines	Nectarines
21869999	Kiwifruit	Kiwifruit
22199999	Avocados	Avocados
22299999	Bananas	Bananas
22399999	Pineapples	Pineapples
22499999	Dates	Dates
22599999	Figs	Figs
22699999	Olives	Olives
22799999	Papayas	Papayas
22801999	Guavas	Guavas
23063999	Blackberries	Blackberries
23071999	Wild Blueberries	Blueberries Wild
23079999	Blueberries	Blueberries
23089999	Boysenberries	Boysenberries
23099999	Caneberries	Caneberries
23179999	Cranberries	Cranberries
23479999	Loganberries	Loganberries
23611999	Red Raspberries	Raspberries Red
23612999	Black Raspberries	Raspberries Black
23619999	All Raspberries	Raspberries All
23799999	Strawberries	Strawberries
25199999	Coffee	Coffee
26199999	Almonds	Almonds
26299999	Hazlenuts	Hazlenuts
26399999	Walnuts (English)	Walnuts (English)
26419999	Improved Pecans	Improved Pecans
26429999	Native Pecans	Pecans Native
26499999	Pecans	Pecans
26799999	Macadamias	Macadamias
26807999	Pistachio Nuts	Pistachio Nuts
26999999	All Nuts	Nuts All
29999999	Fruits & Nuts	Fruit & Nuts All
30199999	Artichoke	Artichoke
30299999	Asparagus	Asparagus
30399299	Beans-Lima - Baby	Beans Lima Baby
30399499	Beans-Lima - Fordhook	Beans Lima Fordhook
30399999	Beans-Lima	Beans Lima All
30429929	Snap Beans For Processing	Beans Snap Beans For Processing
30499999	Beans-Snap	Beans Snap
30599999	Beets	Beets
30799999	Broccoli	Broccoli
30899999	Brussels Sprouts	Brussels Sprouts
31099999	Cabbage	Cabbage
31399999	Carrots	Carrots
31499999	Cauliflower	Cauliflower
31699999	Celery	Celery
32299999	Collards	Collards
32329929	Sweet Corn For Processing	Sweet Corn For Processing
32399999	Corn-Sweet	Corn-Sweet
32598099	Pickle Stocks	Pickle Stocks
32599999	Cucumbers	Cucumbers
33099999	Egg Plant	Egg Plant
33299999	Escarole/Endive	Escarole/Endive
33599999	Garlic	Garlic
33799999	Kale	Kale
34099999	Lettuce-Head	Lettuce Head
34199999	Lettuce-Romaine	Lettuce Romaine
34299999	Lettuce-Leaf	Lettuce Leaf
34399999	Melons-Cantaloups	Melons Cantaloups
34799999	Melons - Honeyball	Melons Honeyball
34899999	Melons-Honeydew	Melons Honeydew
34999999	Melons Cantelope-Honeydew-Watermelon	Melons Cantelope-Honeydew-Watermelon
35499999	Melons-Watermelon	Melons Watermelon
35599999	Mushrooms All	Mushrooms All
35699999	Mustard	Mustard
35799999	Okra	Okra
35899399	Onions - Spring	Onions Spring
35899499	Onions - Summer Storage	Onions Summer Storage
35899599	Onions - Summer Non-Storage	Onions Summer Non-Storage
35899699	Onions - Summer	Onions Summer
35899999	Onions	Onions All
36129929	Green Peas For Processing	Peas Green Peas For Processing
36199999	Peas-Green	Peas Green
36399999	Peppers-Bell	Peppers Bell
36499999	Chile Peppers	Chile Peppers
36699999	Pumpkins	Pumpkins
36799999	Radishes	Radishes
37299999	Shallots	Shallots
37499999	Spinach	Spinach
37599999	Squash	Squash
37799999	Taro	Taro
37829929	Tomatoes For Processing	Tomatoes For Processing
37899999	Tomatoes	Tomatoes All
38199999	Turnip	Turnip
39199199	Potatoes Winter	Potatoes Winter
39199399	Potatoes Spring	Potatoes Spring
39199599	Potatoes Summer	Potatoes Summer
39199799	Potatoes Fall	Potatoes Fall
39199999	Potatoes All	Potatoes All
39299999	Sweetpotatoes	Sweetpotatoes
39903999	3 Major Vegetables (Varies By Season)	3 Major Vegetables (Varies By Season)
39909999	9 Major Vegetables (Varies By Season)	9 Major Vegetables (Varies By Season)
39913999	13 Major Vegetables (Varies By Season)	13 Major Vegetables (Varies By Season)
39919999	25 Major Vegetables (Varies By Season)	25 Major Vegetables (Varies By Season)
39929999	10 Major Vegetables (Varies By Season)	10 Major Vegetables (Varies By Season)
39934999	34 Major Vegetables (Varies By Season)	34 Major Vegetables (Varies By Season)
39991299	12 Major Vegetables (Varies By Season)	12 Major Vegetables (Varies By Season)
39999999	Commercial Vegetables	Commercial Vegetables
40111999	Cows That Calved - Beef	Cattle Cows That Calved - Beef
40112999	Cows That Calved - Milk	Cattle Cows That Calved - Milk
40119999	Cows & Heifers That Calved	Cattle Cows & Heifers That Calved
40129999	Bulls 500+ Lbs	Cattle Bulls 500+ Lbs
40131199	Beef Cow Replacement Heifers To Calve	Cattle Beef Cow Replacement Heifers To Calve
40131999	Heifers 500+ Lbs - Beef Repl	Cattle Heifers 500+ Lbs Beef Replacement
40132199	Milk Cow Replacement Heifers To Calve	Cattle Milk Cow Replacement Heifers To Calve
40132999	Heifers 500+ Lbs - Milk Repl	Cattle Heifers 500+ Lbs Milk Replacement
40133999	Heifers 500+ Lbs - Other	Cattle Heifers 500+ Lbs Other
40139999	Heifers 500+ Lbs	Cattle Heifers 500+ Lbs
40149999	Steers 500+ Lbs	Cattle Steers 500+ Lbs
40159999	Calves Less Than 500 Lbs	Cattle Calves Less Than 500 Lbs
40166999	Cattle All Beef	Cattle All Beef
40167999	Steers And Heifers 500+ Lbs	Cattle Steers And Heifers 500+ Lbs
40169999	Cattle 500+ Lbs	Cattle Cattle 500+ Lbs
40179999	Calf Crop	Cattle Calf Crop
40189999	Calves Other Heifers Steers 500+	Cattle Calves Other Heifers Steers 500+
40199999	Cattle & Calves - All	Cattle Cattle & Calves All
40299999	Cattle On Feed	Cattle Cattle On Feed
40999199	Milk Cows & Production	Cattle Milk Cows & Production
41111999	Breeding Ewes	Sheep Breeding Ewes
41112999	Breeding Rams	Sheep Breeding Rams
41113999	Replacement Lambs	Sheep Replacement Lambs
41119999	Breeding Total Sheep & Lamb	Sheep Breeding Total Sheep & Lamb
41121999	Market Sheep	Sheep Market Sheep
41122999	Market Lambs	Sheep Market Lambs
41129999	Market Total Sheep & Lamb	Sheep Market Total Sheep & Lamb
41133399	Lamb Crop	Sheep Lamb Crop
41299999	Sheep On Feed	Sheep Sheep On Feed
41499999	Wool	Sheep Wool
41799999	Sheep & Lamb Operations	Sheep Sheep & Lamb Operations
41999999	All Sheep	Sheep All Sheep
42111999	Sows And Gilts Bred	Hogs Sows And Gilts Bred
42119999	Breeding	Hogs Breeding
42129199	Barrows & Gilts	Hogs Barrows & Gilts
42129999	Market	Hogs Market
42199999	All	Hogs All
42213399	Sows Farrowed (1000 Head)	Hogs Sows Farrowed (1000 Head)
42223399	Number Of Pigs Per Litter	Hogs Number Of Pigs Per Litter
42233399	Pig Crop (1000 Head)	Hogs Pig Crop (1000 Head)
42999999	Hogs	Hogs All
43299999	Operations	Hogs Operations
44119999	Angora	Goats Angora
44499999	Mohair	Goats Mohair
44999999	All Goats	Goats All Goats
47410099	Beef	Livestock Slaughtered Beef
47410299	Steers	Livestock Slaughtered Steers
47410499	Heifers	Livestock Slaughtered Heifers
47410699	All Cows	Livestock Slaughtered All Cows
47410899	Dairy Cows	Livestock Slaughtered Dairy Cows
47411099	Other Cows	Livestock Slaughtered Other Cows
47411299	Bulls & Stags	Livestock Slaughtered Bulls & Stags
47411999	Cattle	Livestock Slaughtered Cattle
47412099	Veal	Livestock Slaughtered Veal
47412999	Calves	Livestock Slaughtered Calves
47430099	Pork	Livestock Slaughtered Pork
47430599	Barrows & Gilts	Livestock Slaughtered Barrows & Gilts
47431099	Sows	Livestock Slaughtered Sows
47431599	Stags & Boars	Livestock Slaughtered Stags & Boars
47439999	Hogs	Livestock Slaughtered Hogs
47440099	Lamb & Mutton	Livestock Slaughtered Lamb & Mutton
47440299	Mature Sheep	Livestock Slaughtered Mature Sheep
47440499	Lambs & Yearlings	Livestock Slaughtered Lambs & Yearlings
47449999	Sheep & Lambs	Livestock Slaughtered Sheep & Lambs
47451099	Goats	Livestock Slaughtered Goats
47452099	Equine	Livestock Slaughtered Equine
47453099	Bison	Livestock Slaughtered Bison
47499999	Total Red Meat	Livestock Slaughtered Total Red Meat
51191099	Cheese Cottage Curd	Cheese Cottage Curd
51192099	Cheese Cottage Creamed	Cheese Cottage Creamed
51193099	Cheese Cottage Lowfat	Cheese Cottage Lowfat
52210099	Butter	Butter
53047899	Manufactured Dairy Products	Manufactured Dairy Products All
53311199	Milk Condensed Whole Unsweetened Bulk	Milk Condensed Whole Unsweetened Bulk
53311299	Milk Condensed Skim Unsweetened Bulk	Milk Condensed Skim Unsweetened Bulk
53312199	Milk Condensed Whole Sweetened Bulk	Milk Condensed Whole Sweetened Bulk
53312299	Milk Condensed Skim Sweetened Bulk	Milk Condensed Skim Sweetened Bulk
53321599	Milk Skim Evaporated Case	Milk Skim Evaporated Case
53338899	Milk Whole Evaporated & Condensed Case	Milk Whole Evaporated & Condensed Case
53339899	Milk Whole Evap & Sweetened Cond Case	Milk Whole Evap & Sweetened Cond Case
53340099	Buttermilk Condensed & Evaporated	Milk Buttermilk Condensed & Evaporated
53350199	Whey Condensed Sweet Human	Whey Condensed Sweet Human
53350299	Whey Condensed Sweet Animal	Whey Condensed Sweet Animal
53359999	Whey Condensed Total	Whey Condensed Total
54090199	Nonfat Dry Milk For Human Consumption	Milk Nonfat Dry MilK For Human Consumption
54090499	Buttermilk Dry Human	Milk Buttermilk Dry Human
54091399	Milk Dry Whole Package 5+Lbs.	Milk Dry Whole Package 5+Lbs.
54169999	Yogurt Plain & Flavored	Yogurt Plain & Flavored
54300099	Buttermilk Dry Total	Milk Buttermilk Dry Total
54411099	Milk Dry Whole	Milk Dry Whole
54421999	Nonfat Dry Milk For Human Consumption	Milk Nonfat Dry Milk For Human Consumption
54422099	Milk Dry Skim Animal	Milk Dry Skim Animal
54830099	Whey Dry Total	Whey Dry Total
54830199	Dry Whey For Human Consumption	Whey Dry Whey For Human Consumption
54830299	Whey Dry Animal	Whey Dry Animal
54831199	Whey Solids In Wet Blends Human	Whey Solids In Wet Blends Human
54831299	Whey Solids In Wet Blends Animal	Whey Solids In Wet Blends Animal
54832099	Lactose Total	Whey Lactose Total
54832199	Lactose Human	Whey Lactose Human
54832299	Lactose Animal	Whey Lactose Animal
54833199	Whey Reduced Mineral Human	Whey Reduced Mineral Human
54833299	Whey Reduced Mineral Animal	Whey Reduced Mineral Animal
54834199	Whey Reduced Lactose Human	Whey Reduced Lactose Human
54834299	Whey Reduced Lactose Animal	Whey Reduced Lactose Animal
54835199	Whey Protein Concentrate Human	Whey Protein Concentrate Human
54835299	Whey Protein Concentrate Animal	Whey Protein Concentrate Animal
54836099	Whey Reduced Lactose & Mineral Total	Whey Reduced Lactose & Mineral Total
54836199	Whey Reduced Lactose & Mineral Human	Whey Reduced Lactose & Mineral Human
54836299	Whey Reduced Lactose & Mineral Animal	Whey Reduced Lactose & Mineral Animal
55140099	Mellorine Mix Produced	Mellorine Mix Produced
55511099	Ice Cream Mix Produced	Ice Cream Mix Produced
55511299	Ice Cream Nonfat Mix Produced	Ice Cream Nonfat Mix Produced
55512099	Ice Cream Lowfat Mix Produced	Ice Cream Lowfat Mix Produced
55513099	Milk Sherbet Mix Produced	Milk Sherbet Mix Produced
55521199	Ice Cream Hard	Ice Cream Hard
55521399	Ice Cream Nonfat Hard	Ice Cream Nonfat Hard
55521999	Ice Cream Total	Ice Cream Total
55522199	Ice Cream Lowfat Hard	Ice Cream Lowfat Hard
55522299	Ice Cream Lowfat Soft	Ice Cream Lowfat Soft
55522999	Ice Cream Lowfat Total	Ice Cream Lowfat Total
55523199	Milk Sherbet Hard	Milk Sherbet Hard
55523999	Milk Sherbet Total	Milk Sherbet Total
55524999	Ice Cream Nonfat Total	Ice Cream Nonfat Total
55528199	Frozen Dairy Products Other	Frozen Dairy Products Other
55550099	Water Ices	Water Ices
55561099	Yogurt Frozen Mix Produced	Yogurt Frozen Mix Produced
55571199	Yogurt Frozen Reg/Lf Hard	Yogurt Frozen Reg/Lf Hard
55571399	Yogurt Frozen Nonfat Hard	Yogurt Frozen Nonfat Hard
55571999	Yogurt Frozen Total	Yogurt Frozen Total
56000099	Cheese Total	Cheese Total
56300099	Cheese Brick & Muenster Total	Cheese Brick & Muenster Total
56470099	Cheese Italian Soft Other	Cheese Italian Soft Other
56600099	Cheese Cream And Neufchatel Total	Cheese Cream And Neufchatel Total
56611099	Cheddar Cheese	Cheddar Cheese
56612099	Cheese American Colby & Jack & Monterey	Cheese American Colby & Jack & Monterey
56613999	Cheese American Whole Milk Total	Cheese American Whole Milk Total
56614099	Cheese American Part Skim	Cheese American Part Skim
56620099	Cheese Swiss	Cheese Swiss
56631099	Cheese Brick	Cheese Brick
56632099	Cheese Muenster	Cheese Muenster
56640099	Cheese Italian Total	Cheese Italian Total
56641099	Cheese Italian Hard Provolone And Similars	Cheese Italian Hard Provolone And Similars
56642099	Cheese Italian Other Total (Total Less Mozz.)	Cheese Italian Other Total (Total Less Mozz.)
56642199	Cheese Italian Hard Romano And Similars	Cheese Italian Hard Romano And Similars
56643099	Cheese Italian Hard Parmesan And Similars	Cheese Italian Hard Parmesan And Similars
56645099	Cheese Italian Soft Mozzarella	Cheese Italian Soft Mozzarella
56646099	Cheese Italian Soft Ricotta And Similars	Cheese Italian Soft Ricotta And Similars
56649499	Cheese Italian Hard Total	Cheese Italian Hard Total
56649799	Cheese Italian Soft Total	Cheese Italian Soft Total
56650099	Cheese Blue & Gorgonzola	Cheese Blue & Gorgonzola
56661099	Cheese Cream	Cheese Cream
56662099	Cheese Neufchatel	Cheese Neufchatel
56670099	Cheese Limburger	Cheese Limburger
56680199	Cheese Other Total	Cheese Other Total
56711099	Cheese Processed	Cheese Processed
56712099	Cheese Processed Foods & Spreads	Cheese Processed Foods & Spreads
56713099	Cheese Cold Pack & Cheese Foods	Cheese Cold Pack & Cheese Foods
56719999	Processed Cheese Cold Pack Cheese Foods Total	Cheese Processed Cheese Cold Pack Cheese Foods Total
56850099	Cheese Hispanic	Cheese Hispanic
60141999	Light Mature	Chicken Light Mature
60142999	Heavy Mature	Chicken Heavy Mature
60149999	Total Mature	Chicken Total Mature
60199299	Chickens Annual-All Excl Comm Broilers	Chicken Annual All Excluding Commercial Broilers
60499999	Young	Chicken Commercial Broilers
60999999	Total	Chicken Total
61110099	Turkeys - Light	Turkeys Light
61120099	Turkeys - Heavy	Turkeys Heavy
61187999	Young	Turkeys Young
61188999	Old	Turkeys Old
61199099	Turkeys - All	Turkeys All
61199999	Total	Turkeys Total
62999999	Ducks	Ducks
63899999	Other Poultry	Poultry Other
65119999	Chickens-Table Egg Type	Chicken Table Egg Type
65121499	Chickens-Hatching Egg Type	Chicken Hatching Egg Type
65122499	Chickens-Hatching Broiler Type	Chicken Hatching Broiler Type
65129999	Chickens-Hatching Type	Chicken Hatching Type
65199299	Chickens - Excluding Commerical Broilers	Chicken Excluding Commerical Broilers
65199499	Chicken Hatcheries	Chicken Hatcheries
65299499	Turkey Hatchery	Turkey Hatchery
69999999	Total Poultry	Poultry Total
80112299	Ginger Root	Ginger Root
80201899	Peppermint	Peppermint
80202899	Spearmint	Spearmint
83161899	Pea Seed Wrinkled	Seed Wrinkled Pea Seed
95999999	Farm Numbers	Farm Farm Numbers
99999999	Principal Crops	Principal Crops 
\.



-- Nathan additions.
drop table if exists commcode_growth_2007_2015;
create table commcode_growth_2007_2015
(
	commcode integer,
	yield_growth float,
	acreage_growth float,
	price float
);


COPY commcode_growth_2007_2015 (commcode,yield_growth,acreage_growth,price) FROM STDIN DELIMITER AS ',' NULL AS '';
11199199,1.112,0.957,134
15499199,1.079,1.094,690
15825599,1.1,1.0,794
\.

CREATE TABLE nass.commcode_biomass_yield (
    commcode integer,
    praccode integer,
    biomassunit varchar(32),
    biopercrop float,
    biohareff float,
    bioavail float,
    productionunit character varying(32),
    yieldunit character varying(32)
);

