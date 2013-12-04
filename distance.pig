REGISTER /me/Software/elephant-bird/pig/target/elephant-bird-pig-3.0.6-SNAPSHOT.jar
REGISTER /me/Software/pig/build/ivy/lib/Pig/json-simple-1.1.jar
SET elephantbird.jsonloader.nestedLoad 'true'

Register 'udfs.py' using jython as udfs;

SET default_parallel 10

rmf yelp_phoenix_academic_dataset/locations.tsv
rmf yelp_phoenix_academic_dataset/distances.tsv

businesses = LOAD 'yelp_phoenix_academic_dataset/yelp_academic_dataset_business.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json:map[];

/* {open=true, neighborhoods={}, review_count=14, stars=4.0, name=Drybar, business_id=LcAamvosJu0bcPgEVF-9sQ, state=AZ, full_address=3172 E Camelback Rd
Phoenix, AZ85018, categories={(Hair Salons),(Hair Stylists),(Beauty & Spas)}, longitude=-112.0131927, latitude=33.5107772, type=business, city=Phoenix} */
locations = FOREACH businesses GENERATE $0#'business_id' AS business_id:chararray,
                                      $0#'longitude' AS longitude:double,
                                      $0#'latitude' AS latitude:double;

STORE locations INTO 'yelp_phoenix_academic_dataset/locations.tsv';
--locations = LOAD 'yelp_phoenix_academic_dataset/locations.tsv' AS (business_id:chararray, longitude:double, latitude:double);
locations_2 = LOAD 'yelp_phoenix_academic_dataset/locations.tsv' AS (business_id:chararray, longitude:double, latitude:double);

location_comparisons = JOIN locations BY '1', locations_2 BY '1';
STORE location_comparisons INTO 'yelp_phoenix_academic_dataset/comparisons.txt';

/* location_comparisons: {
      locations::business_id: chararray,
      locations::longitude: double,
      locations::latitude: double,
      locations_2::business_id: chararray,
      locations_2::longitude: double,
      locations_2::latitude: double} */
location_comparisons = LOAD 'yelp_phoenix_academic_dataset/comparisons.txt' AS (l1_business_id:chararray,
                                                                     l1_longitude:double,
                                                                     l1_latitude:double,
                                                                     l2_business_id:chararray,
                                                                     l2_longitude:double,
                                                                     l2_latitude:double);

distances = FOREACH location_comparisons GENERATE l1_business_id AS business_id_1,
                                                  l2_business_id AS business_id_2,
                                                  udfs.haversine(l1_longitude,
                                                                 l1_latitude,
                                                                 l2_longitude,
                                                                 l2_latitude) AS distance;
STORE distances INTO 'yelp_phoenix_academic_dataset/distances.tsv';
