REGISTER /Users/rjurney/Software/pig/contrib/piggybank/java/piggybank.jar
DEFINE LENGTH org.apache.pig.piggybank.evaluation.string.LENGTH();

/* MongoDB libraries and configuration */
REGISTER /me/Software/mongo-hadoop/mongo-2.10.1.jar
REGISTER /me/Software/mongo-hadoop/core/target/mongo-hadoop-core-1.1.0-SNAPSHOT.jar
REGISTER /me/Software/mongo-hadoop/pig/target/mongo-hadoop-pig-1.1.0-SNAPSHOT.jar
DEFINE MongoStorage com.mongodb.hadoop.pig.MongoStorage();

import 'ntf_idf.macro';
rmf /tmp/raw_scores.txt
rmf /tmp/ordered_scores.txt

adjectives = LOAD 'yelp_phoenix_academic_dataset/adjectives.tsv' AS (business_id:chararray, adjectives:chararray);
adjectives = FOREACH adjectives GENERATE business_id, FLATTEN(TOKENIZE(adjectives)) AS adjective;
raw_scores = FOREACH (GROUP adjectives BY (business_id, adjective)) GENERATE FLATTEN(group) AS (business_id, adjective), 
                                                                             (int)COUNT_STAR(adjectives) AS total:int;
raw_scores = FILTER raw_scores BY business_id IS NOT NULL and business_id != '';

per_business = FOREACH (GROUP raw_scores BY business_id) {
    sorted = ORDER raw_scores BY total DESC;
    top_20 = LIMIT sorted 20;
    GENERATE group AS business_id, top_20.(adjective, total) AS total_scores;
}
STORE per_business INTO '/tmp/raw_scores.txt';
STORE per_business INTO 'mongodb://localhost/yelp.raw_adjectives_per_business' USING MongoStorage();
 
ntf_idf_scores_per_message = ntf_idf(adjectives, 'business_id', 'adjective');
ordered_scores = FOREACH (GROUP ntf_idf_scores_per_message BY business_id) {
    sorted = ORDER ntf_idf_scores_per_message BY score DESC;
    top_20 = LIMIT sorted 20;
    GENERATE group AS business_id, top_20.(token, score) AS ntf_idf_scores;
}
STORE ordered_scores INTO '/tmp/ordered_scores.txt';
STORE ordered_scores INTO 'mongodb://localhost/yelp.tf_idf_adjectives_per_business' USING MongoStorage();
