import json
import azure.functions as func
from shared.weather_lib import get_forecast_from_openweather, save_forecast_to_db


def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body = req.get_json()
    except:
        return func.HttpResponse(
            json.dumps({"error": "Invalid JSON"}),
            status_code=400,
            mimetype="application/json"
        )

    name = body.get("name")
    city = body.get("city")

    if not name or not city:
        return func.HttpResponse(
            json.dumps({"error": "name and city required"}),
            status_code=400,
            mimetype="application/json"
        )

    forecast = get_forecast_from_openweather(city)
    record_id = save_forecast_to_db(name, city, forecast)

    return func.HttpResponse(
        json.dumps({"message": "saved", "id": record_id}),
        status_code=201,
        mimetype="application/json"
    )
