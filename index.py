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

def init_hash():
    h = {}
    for i in range(0,23):
        h[str(i)] = 0
    return h

def process_hours(hours_days):
    hour_chart_data = init_hash()
    for hour_day in hours_days:
        hour, day = parse_hour(hour_day)
        print hours_days[hour_day]
        hour_chart_data[str(hour)] += hours_days[hour_day]
    return hour_chart_data

def parse_hour(hour_day):
    return hour_day.split("-")

# Controller: Fetch a business and display it
@app.route("/business/<business_id>")
def business(business_id):
  business = businesses.find_one({'business_id': business_id})
  print "Business: " + str(business)
  checks = checkins.find_one({'business_id': business_id})
  hours = process_hours(checks['checkin_info'])
  hours_json = json.dumps(hours)
  return render_template('partials/business.html', business=business, hours_json=hours_json, hours=hours)

if __name__ == "__main__":
  app.run(debug=True)
