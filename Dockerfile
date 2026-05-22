# Bazowy obraz — Python 3.11 slim (lżejszy niż pełen Ubuntu)
FROM python:3.11-slim

# Katalog roboczy w kontenerze
WORKDIR /app

# 1) Najpierw kopiujemy TYLKO requirements.txt
# Dzięki temu warstwa "instalacja zależności" cache'uje się — przy zmianie kodu
# Docker nie reinstaluje wszystkiego od zera.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2) Dopiero teraz kopiujemy kod aplikacji i model
COPY app.py .
COPY mnist_model.keras .

# Port na którym nasłuchuje aplikacja (FastAPI/uvicorn)
EXPOSE 8080

# Komenda startowa kontenera
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
