/* Elephant Bird for JSON parsing */
REGISTER /me/Software/elephant-bird/pig/target/elephant-bird-pig-3.0.6-SNAPSHOT.jar
REGISTER /me/Software/pig/build/ivy/lib/Pig/json-simple-1.1.jar

set default_parallel 5 /* By default, lets have 5 reducers */
SET elephantbird.jsonloader.nestedLoad 'true'

rmf /tmp/reviews.avro
rmf /tmp/businesses.avro
rmf /tmp/users.avro

reviews = LOAD 'yelp_phoenix_academic_dataset/yelp_academic_dataset_review.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json:map[];
reviews = FOREACH reviews GENERATE $0#'type' AS type:chararray,
                                   $0#'business_id' AS business_id:chararray,
                                   $0#'user_id' AS user_id:chararray,
                                   (int)$0#'stars' AS stars:int,
                                   $0#'text' AS text:chararray,
                                   $0#'date' AS date:chararray;

STORE reviews into '/tmp/reviews.avro' USING AvroStorage();


businesses = LOAD 'yelp_phoenix_academic_dataset/yelp_academic_dataset_business.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json:map[];
businesses = FOREACH businesses GENERATE $0#'open' AS open:chararray,
                                  $0#'neighborhoods' as neighborhoods:bag{t:tuple(neighborhood:chararray)},
                                  (int)$0#'review_count' AS review_count:int,
                                  (double)$0#'stars' AS stars:double,
                                  $0#'name' AS name:chararray,
                                  $0#'business_id' AS business_id:chararray,
                                  $0#'state' AS state:chararray,
                                  $0#'full_address' AS full_address:chararray,
                                  $0#'categories' AS categories:bag{t:tuple(category:chararray)},
                                  (double)$0#'longitude' AS longitude:double,
                                  (double)$0#'latitude' AS latitude:double,
                                  $0#'type' AS type:chararray,
                                  $0#'city' AS city:chararray;
STORE businesses INTO '/tmp/businesses.avro' USING AvroStorage();

users = LOAD 'yelp_phoenix_academic_dataset/yelp_academic_dataset_user.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json;
users = FOREACH users GENERATE (int)$0#'review_count' AS review_count:int,
                                  $0#'name' AS name:chararray,
                                  /* $0#'votes' AS votes:tuple(cool:int, funny:int, useful:int), */
                                  $0#'user_id' AS user_id:chararray,
                                  $0#'type' AS type:chararray,
                                  (double)$0#'average_stars' AS average_stars:double;
STORE users INTO '/tmp/users.avro' USING AvroStorage();
