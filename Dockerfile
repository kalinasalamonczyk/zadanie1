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