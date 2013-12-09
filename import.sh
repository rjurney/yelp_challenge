# Import businesses, users, reviews and checkins
mongoimport --db yelp --collection businesses yelp_phoenix_academic_dataset/yelp_academic_dataset_business.json
mongoimport --db yelp --collection users yelp_phoenix_academic_dataset/yelp_academic_dataset_user.json
mongoimport --db yelp --collection reviews yelp_phoenix_academic_dataset/yelp_academic_dataset_review.json
mongoimport --db yelp --collection checkins yelp_phoenix_academic_dataset/yelp_academic_dataset_checkin.json
