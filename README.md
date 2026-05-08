
# Zadanie 1 

**Autor:** Kalina Salamończyk  

## 1. Aplikacja

Aplikacja napisana w Pythonie z użyciem Flask. Po wybraniu kraju 
i miasta wyświetla aktualną temperaturę pobieraną z darmowego 
API Open-Meteo (nie wymaga klucza API).

Po uruchomieniu kontenera aplikacja zapisuje w logach datę 
uruchomienia, imię i nazwisko autora oraz port TCP.

### app.py
import logging
import os
import sys
import datetime
import requests
from flask import Flask, render_template_string, request

PORT = int(os.getenv("PORT", 8080))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)

logger.info("Data uruchomienia: %s", datetime.datetime.now().isoformat())
logger.info("Autor: Kalina Salamonczyk")
logger.info("Port: %d", PORT)

CITIES = {
    "Polska": [
        {"name": "Lublin",   "lat": 51.25, "lon": 22.57},
        {"name": "Warszawa", "lat": 52.23, "lon": 21.01},
        {"name": "Szczecin", "lat": 53.43, "lon": 14.55},
    ],
    "Niemcy": [
        {"name": "Berlin",    "lat": 52.52, "lon": 13.41},
        {"name": "Monachium", "lat": 48.14, "lon": 11.58},
        {"name": "Hamburg",   "lat": 53.55, "lon": 10.00},
    ],
}

TEMPLATE = """
<!doctype html>
<html lang="pl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pogoda</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap');

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Poppins', sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 1rem;
      background: linear-gradient(135deg, #e8d5f5 0%, #fce4ec 50%, #e3f2fd 100%);
    }

    .card {
      background: rgba(255, 255, 255, 0.6);
      backdrop-filter: blur(16px);
      border-radius: 2rem;
      padding: 2.5rem;
      max-width: 420px;
      width: 100%;
      box-shadow: 0 8px 32px rgba(180, 140, 200, 0.2);
      border: 1px solid rgba(255, 255, 255, 0.8);
    }

    h1 {
      font-size: 1.4rem;
      font-weight: 600;
      text-align: center;
      margin-bottom: 2rem;
      color: #7b5ea7;
      letter-spacing: 0.05em;
    }

    label {
      display: block;
      font-size: .8rem;
      font-weight: 600;
      color: #a07cc5;
      margin: 1rem 0 .4rem;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }

    select {
      width: 100%;
      padding: .75rem 1rem;
      border-radius: 1rem;
      border: 1.5px solid #e0c8f0;
      font-size: .95rem;
      font-family: 'Poppins', sans-serif;
      background: rgba(255,255,255,0.8);
      color: #5a3e7a;
      cursor: pointer;
      outline: none;
      transition: border-color .2s;
    }

    select:focus { border-color: #b57bee; }

    button {
      width: 100%;
      padding: .8rem;
      border-radius: 1rem;
      border: none;
      font-size: .95rem;
      font-family: 'Poppins', sans-serif;
      font-weight: 600;
      cursor: pointer;
      margin-top: 1.5rem;
      background: linear-gradient(135deg, #c084e8, #f48fb1);
      color: #fff;
      letter-spacing: 0.04em;
      transition: opacity .2s, transform .1s;
    }

    button:hover { opacity: .9; transform: translateY(-1px); }
    button:active { transform: translateY(0); }

    .weather {
      margin-top: 2rem;
      background: rgba(255,255,255,0.7);
      border-radius: 1.5rem;
      padding: 1.75rem;
      text-align: center;
      border: 1px solid rgba(255,255,255,0.9);
    }

    .city {
      font-size: 1rem;
      font-weight: 600;
      color: #a07cc5;
      margin-bottom: .25rem;
      letter-spacing: 0.05em;
    }

    .temp {
      font-size: 4rem;
      font-weight: 300;
      color: #5a3e7a;
      line-height: 1.1;
      margin: .5rem 0;
    }

    .error {
      color: #e57373;
      margin-top: 1rem;
      text-align: center;
      font-size: .9rem;
    }
  </style>
</head>
<body>
<div class="card">
  <h1>Prognoza Pogody</h1>
  <form method="post">
    <label>Kraj</label>
    <select name="country" onchange="this.form.submit()">
      <option value="">Wybierz kraj</option>
      {% for c in countries %}
        <option value="{{ c }}" {% if c == selected_country %}selected{% endif %}>{{ c }}</option>
      {% endfor %}
    </select>

    {% if cities_in_country %}
    <label>Miasto</label>
    <select name="city_index">
      {% for idx, city in cities_in_country %}
        <option value="{{ idx }}" {% if idx == selected_city_idx %}selected{% endif %}>{{ city.name }}</option>
      {% endfor %}
    </select>
    <button type="submit" name="action" value="weather">Sprawdz Pogode</button>
    {% endif %}
  </form>

  {% if weather %}
  <div class="weather">
    <div class="city">{{ weather.city }}, {{ weather.country }}</div>
    <div class="temp">{{ weather.temp }}°C</div>
  </div>
  {% endif %}

  {% if error %}<p class="error">{{ error }}</p>{% endif %}
</div>
</body>
</html>
"""

app = Flask(__name__)

def get_weather(lat, lon):
    url = (
        "https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}&longitude={lon}"
        "&current=temperature_2m"
        "&forecast_days=1"
    )
    resp = requests.get(url, timeout=5)
    resp.raise_for_status()
    c = resp.json()["current"]

    return {
        "temp": round(c["temperature_2m"]),
    }

@app.route("/health")
def health():
    return {"status": "ok"}, 200

@app.route("/", methods=["GET", "POST"])
def index():
    countries = list(CITIES.keys())
    selected_country = None
    selected_city_idx = 0
    cities_in_country = []
    weather = None
    error = None

    if request.method == "POST":
        selected_country = request.form.get("country")
        selected_city_idx = int(request.form.get("city_index", 0))

        if selected_country in CITIES:
            cities_in_country = list(enumerate(CITIES[selected_country]))

        if request.form.get("action") == "weather" and selected_country:
            city = CITIES[selected_country][selected_city_idx]
            try:
                data = get_weather(city["lat"], city["lon"])
                data["city"] = city["name"]
                data["country"] = selected_country
                weather = data
                logger.info("Pobrano pogode: %s, %s -> %s°C",
                            selected_country, city["name"], data["temp"])
            except Exception as e:
                error = f"Blad pobierania danych: {e}"
                logger.error("Blad: %s", e)

    return render_template_string(
        TEMPLATE,
        countries=countries,
        selected_country=selected_country,
        selected_city_idx=selected_city_idx,
        cities_in_country=cities_in_country,
        weather=weather,
        error=error,
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)


## 2. Dockerfile

Obraz bazowy to python:3.12-alpine co znacząco zmniejsza rozmiar 
obrazu. Aplikacja uruchamiana jest jako zwykły użytkownik (nie root).
Kolejność COPY jest celowa — najpierw requirements.txt żeby 
cache Dockera działał poprawnie.

### Dockerfile

# syntax=docker/dockerfile:1
# Autor: Kalina Salamończyk

FROM python:3.12-alpine AS builder

WORKDIR /build

# najpierw kopiuję requirements żeby docker cache działał lepiej
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# finalny obraz
FROM python:3.12-alpine

LABEL org.opencontainers.image.authors="Kalina Salamończyk"
LABEL org.opencontainers.image.title="Weather App"

WORKDIR /app

# kopiuję zainstalowane paczki z buildera
COPY --from=builder /install /usr/local

# kopiuję kod aplikacji
COPY app.py .

ENV PORT=8080
EXPOSE 8080

# healthcheck co 30s sprawdza czy aplikacja działa
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

# uruchamiam jako zwykły użytkownik, nie root
RUN adduser -D appuser
USER appuser

CMD ["python", "app.py"]


## Punkt 3 — Polecenia

### a) Budowanie obrazu

```bash
docker build -t weather-app:v1 .
```

### b) Uruchomienie kontenera

```bash
docker run -d --name pogoda -p 8080:8080 weather-app:v1
```

### c) Logi z uruchomienia

```bash
docker logs pogoda
```

Output: 
PS C:\Users\kalin\Z1> docker logs pogoda
2026-05-08 12:58:34,341 [INFO] Data uruchomienia: 2026-05-08T12:58:34.341413
2026-05-08 12:58:34,342 [INFO] Autor: Kalina Salamonczyk
2026-05-08 12:58:34,342 [INFO] Port: 8080
 * Serving Flask app 'app'
 * Debug mode: off
2026-05-08 12:58:34,362 [INFO] WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:8080
 * Running on http://172.17.0.2:8080
2026-05-08 12:58:34,363 [INFO] Press CTRL+C to quit


### d) Liczba warstw i rozmiar obrazu

```bash
docker images weather-app:v1
docker inspect weather-app:v1 --format='{{len .RootFS.Layers}}'
```

Output:

PS C:\Users\kalin\Z1> docker images weather-app:v1
                                                                           i Info →   U  In Use
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
weather-app:v1   131035b7c909       86.1MB         20.7MB    U   

PS C:\Users\kalin\Z1> docker inspect weather-app:v1 --format='{{len .RootFS.Layers}}'
8
