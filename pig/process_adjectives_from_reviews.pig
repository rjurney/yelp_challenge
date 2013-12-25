REGISTER /Users/rjurney/Software/pig/contrib/piggybank/java/piggybank.jar
DEFINE LENGTH org.apache.pig.piggybank.evaluation.string.LENGTH();

/* MongoDB libraries and configuration */
REGISTER /me/Software/mongo-hadoop/mongo-2.10.1.jar
REGISTER /me/Software/mongo-hadoop/core/target/mongo-hadoop-core-1.1.0-SNAPSHOT.jar
REGISTER /me/Software/mongo-hadoop/pig/target/mongo-hadoop-pig-1.1.0-SNAPSHOT.jar
DEFINE MongoStorage com.mongodb.hadoop.pig.MongoStorage();

set default_parallel 10
import 'ntf_idf.macro';

rmf /tmp/raw_scores.txt
rmf /tmp/ntf_idf_scores.txt

adjectives = LOAD '/tmp/adjectives.tsv' AS (business_id:chararray, name:chararray, adjectives:chararray);
adjectives = FOREACH adjectives GENERATE business_id, 
                                         name,
                                         FLATTEN(TOKENIZE(adjectives)) AS adjective;

/* Remove stop words. Note use of replicated join for mucho velocidad */
stop_words = LOAD '../data/stopwords.txt' AS (word:chararray);
adjectives = JOIN adjectives BY adjective LEFT OUTER, stop_words BY word using 'replicated';
adjectives = FILTER adjectives BY stop_words::word IS NULL;

raw_scores = FOREACH (GROUP adjectives BY (business_id, name, adjective)) GENERATE FLATTEN(group) AS (business_id, name, adjective), 
                                                                                   (int)COUNT_STAR(adjectives) AS total:int;
raw_scores = FILTER raw_scores BY business_id IS NOT NULL and business_id != '';

per_business = FOREACH (GROUP raw_scores BY (business_id, name)) {
    sorted = ORDER raw_scores BY total DESC;
    top_100 = LIMIT sorted 100;
    GENERATE FLATTEN(group) AS (business_id, name), top_100.(adjective, total) AS total_scores;
}
STORE per_business INTO 'mongodb://localhost/yelp.raw_words_per_business' USING MongoStorage();
 
ntf_idf_scores_per_message = ntf_idf(adjectives, 'business_id', 'name', 'adjective');

ordered_scores = FOREACH (GROUP ntf_idf_scores_per_message BY (business_id, name)) {
    sorted = ORDER ntf_idf_scores_per_message BY score DESC;
    top_100 = LIMIT sorted 100;
    GENERATE FLATTEN(group) AS (business_id, name), top_100.(adjective, score) AS ntf_idf_scores;
}
STORE ordered_scores INTO '/tmp/ntf_idf_scores.txt';
STORE ordered_scores INTO 'mongodb://localhost/yelp.ntf_idf_words_per_business' USING MongoStorage();
