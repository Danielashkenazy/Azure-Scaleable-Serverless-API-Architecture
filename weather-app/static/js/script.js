// עדכן ל-URL של API Gateway שלך (ללא הסלש בסוף)
const API_BASE_URL = "https://weather-apimm-6050.azure-api.net";

// ===== DEBUG MODE =====
const DEBUG = true;
function debugLog(message, data = null) {
  if (DEBUG) {
    const timestamp = new Date().toISOString();
    console.log(`[DEBUG ${timestamp}] ${message}`);
    if (data !== null) {
      console.log('[DEBUG DATA]', data);
    }
  }
}

debugLog('Script loaded', { API_BASE_URL });

const form = document.getElementById("weather-form");
const nameInput = document.getElementById("name");
const cityInput = document.getElementById("city");
const statusDiv = document.getElementById("status");
const forecastSection = document.getElementById("forecast");
const forecastCity = document.getElementById("forecast-city");
const forecastList = document.getElementById("forecast-list");
const saveBtn = document.getElementById("save-btn");

debugLog('DOM elements loaded', {
  form: !!form,
  nameInput: !!nameInput,
  cityInput: !!cityInput,
  statusDiv: !!statusDiv
});

let lastForecast = null;
let lastCity = null;

function setStatus(message, type = "info") {
  debugLog(`Status update: [${type}] ${message}`);
  statusDiv.textContent = message;
  statusDiv.className = `status ${type}`;
}

function renderForecast(data) {
  debugLog('renderForecast called', data);
  
  if (!data || !Array.isArray(data.forecast)) {
    debugLog('No valid forecast data, hiding section');
    forecastSection.classList.add("hidden");
    return;
  }

  debugLog(`Rendering ${data.forecast.length} forecast items`);
  forecastCity.textContent = `${data.city}, ${data.country || ""}`.trim();
  forecastList.innerHTML = "";

  data.forecast.forEach((day, index) => {
    debugLog(`Rendering day ${index + 1}`, day);
    
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

  debugLog('Forecast rendered successfully, showing section');
  forecastSection.classList.remove("hidden");
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  debugLog('=== FORM SUBMIT EVENT ===');

  const name = nameInput.value.trim();
  const city = cityInput.value.trim();

  debugLog('Form values', { name, city });

  if ( !city) {
    debugLog('Validation failed: missing city');
    setStatus("Please fill both name and city.", "error");
    return;
  }

  setStatus("Loading forecast...", "info");
  saveBtn.disabled = true;

  try {
    const url = `${API_BASE_URL}/weather/weather?city=${encodeURIComponent(city)}`;
    debugLog('Making API request', { 
      url, 
      method: 'GET',
      encodedCity: encodeURIComponent(city)
    });

    console.log('===== FETCH REQUEST =====');
    console.log('URL:', url);
    console.log('Origin:', window.location.origin);
    console.log('Timestamp:', new Date().toISOString());

    const res = await fetch(url);
    
    debugLog('Response received', {
      status: res.status,
      statusText: res.statusText,
      ok: res.ok,
      headers: Object.fromEntries(res.headers.entries()),
      url: res.url,
      redirected: res.redirected,
      type: res.type
    });

    console.log('===== RESPONSE DETAILS =====');
    console.log('Status:', res.status);
    console.log('Status Text:', res.statusText);
    console.log('OK:', res.ok);
    console.log('Headers:', Object.fromEntries(res.headers.entries()));
    
    if (!res.ok) {
      debugLog(`Request failed with status ${res.status}`);
      const contentType = res.headers.get('content-type');
      debugLog('Response Content-Type:', contentType);
      
      let errData = {};
      try {
        const responseText = await res.text();
        debugLog('Raw error response text:', responseText);
        
        if (contentType && contentType.includes('application/json')) {
          errData = JSON.parse(responseText);
          debugLog('Parsed error JSON:', errData);
        } else {
          debugLog('Non-JSON error response');
          errData = { error: responseText || 'Unknown error' };
        }
      } catch (parseErr) {
        debugLog('Failed to parse error response', parseErr);
        errData = { error: 'Failed to parse error response' };
      }
      
      throw new Error(errData.error || `Request failed with ${res.status}`);
    }

    debugLog('Response OK, parsing JSON...');
    const responseText = await res.text();
    debugLog('Raw response text:', responseText);
    
    const data = JSON.parse(responseText);
    debugLog('Parsed response data:', data);
    
    lastForecast = data;
    lastCity = data.city;

    renderForecast(data);

    setStatus("Forecast loaded. You can save it now.", "success");
    saveBtn.disabled = false;
  } catch (err) {
    console.error('===== ERROR CAUGHT =====');
    console.error('Error message:', err.message);
    console.error('Error stack:', err.stack);
    console.error('Full error object:', err);
    
    debugLog('Error in form submit handler', {
      message: err.message,
      stack: err.stack,
      name: err.name
    });
    
    setStatus("Failed to load forecast: " + err.message, "error");
    forecastSection.classList.add("hidden");
  }
});

saveBtn.addEventListener("click", async () => {
  debugLog('=== SAVE BUTTON CLICKED ===');
  
  const name = nameInput.value.trim();
  const city = cityInput.value.trim();

  debugLog('Save values', { name, city });

  if (!name || !city) {
    debugLog('Validation failed: missing name or city');
    setStatus("Please fill both name and city.", "error");
    return;
  }

  setStatus("Saving forecast...", "info");
  saveBtn.disabled = true;

  try {
    const saveUrl = `${API_BASE_URL}/weather/save`;
    const payload = { name, city };
    
    debugLog('Making save request', { 
      url: saveUrl, 
      method: 'POST',
      payload 
    });

    console.log('===== SAVE REQUEST =====');
    console.log('URL:', saveUrl);
    console.log('Payload:', payload);
    console.log('Origin:', window.location.origin);

    const res = await fetch(saveUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    debugLog('Save response received', {
      status: res.status,
      statusText: res.statusText,
      ok: res.ok,
      headers: Object.fromEntries(res.headers.entries())
    });

    console.log('===== SAVE RESPONSE =====');
    console.log('Status:', res.status);
    console.log('Status Text:', res.statusText);
    console.log('OK:', res.ok);

    const responseText = await res.text();
    debugLog('Save raw response:', responseText);
    
    let data = {};
    try {
      data = JSON.parse(responseText);
      debugLog('Parsed save response:', data);
    } catch (parseErr) {
      debugLog('Failed to parse save response', parseErr);
      data = { error: responseText || 'Unknown error' };
    }

    if (!res.ok) {
      debugLog(`Save failed with status ${res.status}`);
      throw new Error(data.error || `Save failed with ${res.status}`);
    }

    debugLog('Save successful!');
    setStatus("Forecast saved successfully!", "success");
  } catch (err) {
    console.error('===== SAVE ERROR =====');
    console.error('Error message:', err.message);
    console.error('Error stack:', err.stack);
    console.error('Full error object:', err);
    
    debugLog('Error in save handler', {
      message: err.message,
      stack: err.stack,
      name: err.name
    });
    
    setStatus("Failed to save forecast: " + err.message, "error");
  } finally {
    saveBtn.disabled = false;
  }
});

// Log when script finishes loading
debugLog('=== SCRIPT INITIALIZATION COMPLETE ===');
console.log('%c🔍 Debug Mode Enabled', 'color: green; font-weight: bold; font-size: 16px');
console.log('Check console for detailed API call information');
console.log('API Base URL:', API_BASE_URL);
