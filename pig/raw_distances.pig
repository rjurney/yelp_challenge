REGISTER /me/Software/elephant-bird/pig/target/elephant-bird-pig-3.0.6-SNAPSHOT.jar
REGISTER /me/Software/pig/build/ivy/lib/Pig/json-simple-1.1.jar
SET elephantbird.jsonloader.nestedLoad 'true'

REGISTER 'udfs.py' using streaming_python AS udfs;
SET default_parallel 10

rmf ../yelp_phoenix_academic_dataset/locations.tsv
rmf ../yelp_phoenix_academic_dataset/distances.tsv

businesses = LOAD '../yelp_phoenix_academic_dataset/yelp_academic_dataset_business.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json:map[];

/* {open=true, neighborhoods={}, review_count=14, stars=4.0, name=Drybar, business_id=LcAamvosJu0bcPgEVF-9sQ, state=AZ, full_address=3172 E Camelback Rd
Phoenix, AZ85018, categories={(Hair Salons),(Hair Stylists),(Beauty & Spas)}, longitude=-112.0131927, latitude=33.5107772, type=business, city=Phoenix} */
raw_locations = FOREACH businesses GENERATE $0#'business_id' AS business_id:chararray,
                                        (float)$0#'longitude' AS longitude:float,
                                        (float)$0#'latitude' AS latitude:float,
                                        $0#'categories' AS categories:bag{t:tuple(category:chararray)};
flat_locations = FOREACH raw_locations GENERATE business_id, 
                                                longitude, 
                                                latitude, 
                                                FLATTEN(categories) AS category;

STORE flat_locations INTO '../yelp_phoenix_academic_dataset/locations.tsv';

locations = flat_locations;
locations_2 = LOAD '../yelp_phoenix_academic_dataset/locations.tsv' AS (business_id:chararray, longitude:float, latitude:float, category:chararray);

location_comparisons = JOIN locations BY category, locations_2 BY category USING 'replicated';                                                        
distances = FOREACH location_comparisons GENERATE flat_locations::business_id AS business_id_1,
                                                  locations_2::business_id AS business_id_2,
                                                  flat_locations::category AS category,
                                                  udfs.haversine(flat_locations::longitude,
                                                                 flat_locations::latitude,
                                                                 locations_2::longitude,
                                                                 locations_2::latitude) AS distance;
/* Drop the category tag, then distinct - to filter multiple tag distances between the same businesses */
without_repeats = FOREACH distances GENERATE business_id_1, business_id_2, distance;
without_repeats = FILTER without_repeats BY business_id_1 != business_id_2;
without_repeast = DISTINCT without_repeats;

STORE without_repeast INTO 'yelp_phoenix_academic_dataset/distances.tsv';
