db.businesses.ensureIndex({'business_id': 1});
db.checkins.ensureIndex({'business_id': 1});
db.nearest_businesses.ensureIndex({'business_id': 1});
db.reviews.ensureIndex({'review_id': 1});
db.reviews.ensureIndex({'business_id': 1});
db.ntf_idf_adjectives_per_business.ensureIndex({'business_id': 1});
db.raw_words_per_business.ensureIndex({'business_id': 1});
