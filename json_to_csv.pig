REGISTER /me/Software/elephant-bird/pig/target/elephant-bird-pig-3.0.6-SNAPSHOT.jar
REGISTER /me/Software/pig/build/ivy/lib/Pig/json-simple-1.1.jar
SET elephantbird.jsonloader.nestedLoad 'true'

SET default_parallel 10

businesses = LOAD 'yelp_phoenix_academic_dataset/yelp_academic_dataset_business.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json:map[];

/* {open=true, neighborhoods={}, review_count=14, stars=4.0, name=Drybar, business_id=LcAamvosJu0bcPgEVF-9sQ, state=AZ, full_address=3172 E Camelback Rd
Phoenix, AZ85018, categories={(Hair Salons),(Hair Stylists),(Beauty & Spas)}, longitude=-112.0131927, latitude=33.5107772, type=business, city=Phoenix} */
tsv = FOREACH businesses GENERATE $0#'review_count' AS review_count,
                                  $0#'stars' AS stars,
                                  $0#'name' AS name,
                                  $0#'business_id' AS business_id,
                                  $0#'state' AS state,
                                  $0#'city' AS city,
                                  $0#'full_address' AS full_address,
                                  $0#'longitude' AS longitude,
                                  $0#'latitude' AS latitude,
                                  $0#'type' AS type;
store tsv into 'yelp_phoenix_academic_dataset/business.tsv';
