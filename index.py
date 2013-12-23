from flask import Flask, render_template, request
import pymongo
import json
import re

# Setup Flask
app = Flask(__name__)

# Setup Mongo
conn = pymongo.Connection() # defaults to localhost
db = conn.yelp

businesses = db['businesses']
users = db['users']
reviews = db['reviews']
checkins = db['checkins']
nearest_businesses = db['nearest_businesses']

def init_zero_hash():
    h = []
    for i in range(0,24):
        h.append({'label': str(i), 'value': 0})
    return h

def parse_hour(hour_day):
    return hour_day.split("-")

def process_hours(hours_days):
    hour_chart_data = init_zero_hash()
    for hour_day in hours_days:
        hour, day = parse_hour(hour_day)
        hour_chart_data[int(hour)]['value'] += hours_days[hour_day]
    return hour_chart_data

def map_degree_to_zoom(degree_value):
    # Determined by experimentation with Leaflet UI and MAX() of distances in Pig
    range_min = 0
    range_max = 142
    zoom_min = 7
    zoom_max = 16
    
    # Compute ranges
    range_span = range_max - range_min
    zoom_span = zoom_max - zoom_min
    
    # Convert the left range into a 0-1 range (float)
    value_scaled = float(degree_value - range_min) / float(range_span)
    
    # Convert the 0-1 range into a value in the right range.
    return int(zoom_max - (value_scaled * zoom_span)) - 1

# Controller: Fetch a business and display it
@app.route("/business/<business_id>")
def business(business_id):
  business = businesses.find_one({'business_id': business_id})
  print "Business: " + str(business)
  checks = checkins.find_one({'business_id': business_id})
  if checks:
    hours = process_hours(checks['checkin_info'])
  else:
    hours = None
  hours_json = json.dumps([{'key': 'Checkins Per Hour', 'values': hours}])
  revs = reviews.find({'business_id': business_id}).sort('date', pymongo.DESCENDING)
  nearby = nearest_businesses.find_one({'business_id': business_id})
  zoom_level = map_degree_to_zoom(nearby['range'])
  return render_template('partials/business.html', business=business, 
                                                   hours_json=hours_json, 
                                                   hours=hours, 
                                                   revs=revs, 
                                                   nearby=nearby['nearest_businesses'], 
                                                   zoom_level=zoom_level)

# Controller: Fetch a review and display it
@app.route("/review/<review_id>")
def review(review_id):
    review = reviews.find_one({'review_id': review_id})
    business = businesses.find_one({'business_id': review['business_id']})
    user = users.find_one({'user_id': review['user_id']})
    print "Review: " + str(review)
    return render_template('partials/review.html', review=review, business=business, user=user)

if __name__ == "__main__":
  app.run(debug=True)
