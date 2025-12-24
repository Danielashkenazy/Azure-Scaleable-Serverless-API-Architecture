import logging
import json
import azure.functions as func
from shared.weather_lib import get_forecast_from_openweather

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Weather function called")

    city = req.params.get("city")
    logging.info(f"City param = {city}")

    if not city:
        logging.error("No city provided")
        return func.HttpResponse(
            json.dumps({"error": "city required"}),
            status_code=400,
            mimetype="application/json",
        )

    try:
        data = get_forecast_from_openweather(city)
        logging.info(f"Forecast result: {data}")

        return func.HttpResponse(
            json.dumps(data),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        logging.exception("Crash inside weather()")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )
