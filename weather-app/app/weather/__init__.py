import json
import azure.functions as func
from shared.weather_lib import get_forecast_from_openweather


def main(req: func.HttpRequest) -> func.HttpResponse:
    city = req.params.get("city")
    name = req.params.get("name")

    if not city:
        return func.HttpResponse(
            json.dumps({"error": "city required"}),
            status_code=400,
            mimetype="application/json",
        )

    data = get_forecast_from_openweather(city)

    return func.HttpResponse(
        json.dumps(data),
        status_code=200,
        mimetype="application/json"
    )
