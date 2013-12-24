REGISTER 'udfs.py' USING streaming_python AS udfs;

rmf /tmp/adjectives.tsv
SET default_parallel 10

reviews = LOAD '/tmp/reviews.avro' USING AvroStorage();
reviews = FOREACH reviews GENERATE business_id, text;
businesses = LOAD '/tmp/businesses.avro' USING AvroStorage();
businesses = FOREACH businesses GENERATE business_id, name;
joined = JOIN reviews BY business_id, businesses BY business_id USING 'replicated';
words = FOREACH joined GENERATE businesses::business_id, name, udfs.adjectives(text) AS tokens;
STORE words INTO '/tmp/adjectives.tsv';
