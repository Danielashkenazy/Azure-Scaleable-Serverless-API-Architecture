// עדכן ל-URL של API Gateway שלך (ללא הסלש בסוף)
const API_BASE_URL = "___API_URL___";

const form = document.getElementById("weather-form");
const nameInput = document.getElementById("name");
const cityInput = document.getElementById("city");
const statusDiv = document.getElementById("status");
const forecastSection = document.getElementById("forecast");
const forecastCity = document.getElementById("forecast-city");
const forecastList = document.getElementById("forecast-list");
const saveBtn = document.getElementById("save-btn");

let lastForecast = null;
let lastCity = null;

function setStatus(message, type = "info") {
  statusDiv.textContent = message;
  statusDiv.className = `status ${type}`;
}

function renderForecast(data) {
  if (!data || !Array.isArray(data.forecast)) {
    forecastSection.classList.add("hidden");
    return;
  }

  forecastCity.textContent = `${data.city}, ${data.country || ""}`.trim();
  forecastList.innerHTML = "";

  data.forecast.forEach((day) => {
    const card = document.createElement("div");
    card.className = "forecast-card";

    const date = document.createElement("div");
    date.className = "forecast-date";
    date.textContent = day.date;

    const desc = document.createElement("div");
    desc.className = "forecast-desc";
    desc.textContent = day.description || "";

    const temp = document.createElement("div");
    temp.className = "forecast-temp";
    temp.textContent = `${Math.round(day.temp)}°C (feels ${Math.round(
      day.feels_like
    )}°C)`;

    const extra = document.createElement("div");
    extra.className = "forecast-extra";
    extra.textContent = `Humidity: ${day.humidity}%`;

    card.appendChild(date);
    card.appendChild(desc);
    card.appendChild(temp);
    card.appendChild(extra);

    forecastList.appendChild(card);
  });

  forecastSection.classList.remove("hidden");
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const name = nameInput.value.trim();
  const city = cityInput.value.trim();

  if ( !city) {
    setStatus("Please fill both name and city.", "error");
    return;
  }

  setStatus("Loading forecast...", "info");
  saveBtn.disabled = true;

  try {
    const url = `${API_BASE_URL}/weather?city=${encodeURIComponent(city)}`;

    const res = await fetch(url);
    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      throw new Error(errData.error || `Request failed with ${res.status}`);
    }

    const data = await res.json();
    lastForecast = data;
    lastCity = data.city;

    renderForecast(data);

    setStatus("Forecast loaded. You can save it now.", "success");
    saveBtn.disabled = false;
  } catch (err) {
    console.error(err);
    setStatus("Failed to load forecast: " + err.message, "error");
    forecastSection.classList.add("hidden");
  }
});

saveBtn.addEventListener("click", async () => {
  const name = nameInput.value.trim();
  const city = cityInput.value.trim();

  if (!name || !city) {
    setStatus("Please fill both name and city.", "error");
    return;
  }

  setStatus("Saving forecast...", "info");
  saveBtn.disabled = true;

  try {
    const res = await fetch(`${API_BASE_URL}/save`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name, city }),
    });

    const data = await res.json();

    if (!res.ok) {
      throw new Error(data.error || `Save failed with ${res.status}`);
    }

    setStatus("Forecast saved successfully!", "success");
  } catch (err) {
    console.error(err);
    setStatus("Failed to save forecast: " + err.message, "error");
  } finally {
    saveBtn.disabled = false;
  }
});
