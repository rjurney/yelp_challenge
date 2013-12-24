REGISTER 'udfs.py' USING streaming_python AS udfs;

rmf /tmp/adjectives.tsv

set default_parallel 20

reviews = LOAD '/tmp/reviews.avro' USING AvroStorage();
nouns = FOREACH reviews GENERATE business_id, udfs.adjectives(text) AS adjectives;
STORE nouns into '/tmp/adjectives.tsv';
