/* MongoDB libraries and configuration */
REGISTER /me/Software/mongo-hadoop/mongo-2.10.1.jar
REGISTER /me/Software/mongo-hadoop/core/target/mongo-hadoop-core-1.1.0-SNAPSHOT.jar
REGISTER /me/Software/mongo-hadoop/pig/target/mongo-hadoop-pig-1.1.0-SNAPSHOT.jar
DEFINE MongoStorage com.mongodb.hadoop.pig.MongoStorage();

/* Elephant Bird for JSON parsing */
REGISTER /me/Software/elephant-bird/pig/target/elephant-bird-pig-3.0.6-SNAPSHOT.jar
REGISTER /me/Software/pig/build/ivy/lib/Pig/json-simple-1.1.jar

SET default_parallel 5 /* By default, lets have 5 reducers */
SET elephantbird.jsonloader.nestedLoad 'true'

set default_parallel 10

rmf /tmp/with_coords.json

raw_distances = LOAD 'yelp_phoenix_academic_dataset/distances.tsv' AS (business_1:chararray, business_2:chararray, distance:float);
raw_distances = FILTER raw_distances BY business_1 != business_2;

businesses = LOAD '/tmp/businesses.avro' USING AvroStorage();
businesses = FOREACH businesses GENERATE business_id, name, latitude, longitude;
with_coords = JOIN raw_distances BY business_2, businesses BY business_id USING 'replicated';
STORE with_coords INTO '/tmp/with_coords.json' USING JsonStorage();

with_coords = LOAD '/tmp/with_coords.json' using com.twitter.elephantbird.pig.load.JsonLoader() as json:map[];
with_coords = FOREACH with_coords GENERATE $0#'raw_distances::business_2' AS business_2:chararray,
                                           $0#'raw_distances::distance' AS distance:chararray,
                                           $0#'businesses::business_id' AS business_id:chararray,
                                           $0#'raw_distances::business_1' AS business_1:chararray,
                                           $0#'businesses::latitude' AS latitude:float,
                                           $0#'businesses::longitude' AS longitude:float,
                                           $0#'businesses::name' AS name:chararray;

nearest_businesses = FOREACH (GROUP with_coords BY business_1) {
    sorted = ORDER with_coords BY distance;
    top_10 = LIMIT sorted 10;
    GENERATE group AS business_id, 
             (float)MAX(top_10.distance) AS range:float, 
             top_10.(business_2, name, latitude, longitude) AS nearest_businesses;
}
STORE nearest_businesses INTO 'mongodb://localhost/yelp.nearest_businesses' USING MongoStorage();
