from flask import Flask, request, jsonify
from redis import Redis
import random
import time
import re

app = Flask(__name__)
redis = Redis(host="election-testing-redis", port=6379)

UPDATE_INTERVAL = 5 * 60
COUNTY_PREFIX = "county:"
EXPIRATION_TIME = 2 * 60 * 60  # 2 hours


def validate_county_name(county):
    if not county:
        return False
    # Allow only letters, numbers, spaces, and hyphens
    if not re.match(r"^[a-zA-Z0-9\s-]+$", county):
        return False
    # Limit the length of the county name
    if len(county) > 50:
        return False
    return True


@app.route("/")
def hello():
    return "Yo!"


@app.route("/clear_cache", methods=["GET"])
def clear_cache():
    keys_to_delete = [
        key for key in redis.keys() if key.decode().startswith(COUNTY_PREFIX)
    ]

    if keys_to_delete:
        redis.delete(*keys_to_delete)

    return jsonify({"message": "All data has been deleted."})


@app.route("/county", methods=["GET"])
def get_county_value():
    county = request.args.get("county")
    if not validate_county_name(county):
        return jsonify({"error": "Invalid county parameter"}), 400

    county_key = COUNTY_PREFIX + county

    try:
        county_data = redis.hgetall(county_key)
        current_time = time.time()

        if county_data:
            last_updated = float(county_data[b"timestamp"])
            if current_time - last_updated < UPDATE_INTERVAL:
                value = int(county_data[b"value"])
                remaining_time = UPDATE_INTERVAL - (current_time - last_updated)
            else:
                value = random.randint(5000, 30000)
                redis.hset(
                    county_key, mapping={"value": value, "timestamp": current_time}
                )
                redis.expire(county_key, EXPIRATION_TIME)
                last_updated = current_time
                remaining_time = UPDATE_INTERVAL
        else:
            value = random.randint(5000, 30000)
            redis.hset(county_key, mapping={"value": value, "timestamp": current_time})
            redis.expire(county_key, EXPIRATION_TIME)
            last_updated = current_time
            remaining_time = UPDATE_INTERVAL

        next_update_time = last_updated + UPDATE_INTERVAL

        response = {
            "county": county,
            "value": value,
            "last-modified": time.strftime(
                "%Y-%m-%d %H:%M:%S", time.localtime(last_updated)
            ),
            "next-update": time.strftime(
                "%Y-%m-%d %H:%M:%S", time.localtime(next_update_time)
            ),
            "next-update-in-seconds": int(remaining_time)
        }

        return jsonify(response)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
