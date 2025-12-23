import os
import json
import psycopg2
import psycopg2.extras
import requests
from datetime import datetime, timezone

DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
OPENWEATHER_API_KEY = os.getenv("OPENWEATHER_API_KEY")

db_conn = None

def get_db_conn():
    global db_conn
    if db_conn is not None and db_conn.closed == 0:
        return db_conn

    db_conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )
    return db_conn


def get_forecast_from_openweather(city: str):
    url = "https://api.openweathermap.org/data/2.5/forecast"
    params = {"q": city, "appid": OPENWEATHER_API_KEY, "units": "metric"}

    resp = requests.get(url, params=params, timeout=10)
    resp.raise_for_status()
    data = resp.json()

    seen = set()
    forecast = []

    for entry in data.get("list", []):
        date = entry.get("dt_txt", "").split(" ")[0]
        if date in seen:
            continue
        seen.add(date)

        main = entry.get("main", {})
        weather = entry.get("weather", [{}])[0]

        forecast.append({
            "date": date,
            "temp": main.get("temp"),
            "feels_like": main.get("feels_like"),
            "humidity": main.get("humidity"),
            "description": weather.get("description"),
        })

        if len(forecast) >= 5:
            break

    return {
        "city": data.get("city", {}).get("name"),
        "country": data.get("city", {}).get("country"),
        "forecast": forecast,
    }


def save_forecast_to_db(username, city, forecast):
    conn = get_db_conn()
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS user_forecasts (
                id SERIAL PRIMARY KEY,
                username TEXT,
                city TEXT,
                forecast_json JSONB,
                created_at TIMESTAMPTZ DEFAULT NOW()
            );
        """)

        cur.execute("""
            INSERT INTO user_forecasts (username, city, forecast_json, created_at)
            VALUES (%s, %s, %s, %s)
            RETURNING id;
        """, (username, city, json.dumps(forecast), datetime.now(timezone.utc)))

        row = cur.fetchone()
        conn.commit()
        return row["id"]
