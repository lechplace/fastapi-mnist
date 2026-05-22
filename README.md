# fastapi-mnist

Mini API serwujące wytrenowany model klasyfikacji cyfr MNIST. Zbudowane na **FastAPI** + **Keras/TensorFlow**, zapakowane w obraz Docker i gotowe do wdrożenia na **Google Cloud Run**.

## Architektura

- `app.py` — aplikacja FastAPI z trzema endpointami (`/`, `/health`, `/predict`).
- `mnist_model.keras` — wytrenowany model (wczytywany **raz** przy starcie aplikacji, nie przy każdym requeście).
- `Dockerfile` — obraz oparty na `python:3.11-slim`, zależności instalowane z `requirements.txt`.
- Skrypty `*.sh` — pomocnicze polecenia do konfiguracji i wdrożenia na GCP.

## Endpointy

| Metoda | Ścieżka    | Opis                                                          |
| ------ | ---------- | ------------------------------------------------------------ |
| GET    | `/`        | Status i metadane modelu.                                     |
| GET    | `/health`  | Health check dla load balancerów / Kubernetes.               |
| POST   | `/predict` | Predykcja cyfry dla obrazu 28x28 floatów w zakresie `[0, 1]`. |

### `POST /predict`

**Request:**

```json
{ "image": [[0.0, 0.1, ...], ... ] }
```

`image` to macierz `28×28` floatów znormalizowanych do `[0, 1]`. Inny kształt zwraca `400`.

**Response:**

```json
{
  "predicted_class": 7,
  "probabilities": [0.001, 0.002, ..., 0.95]
}
```

## Wymagania

- Python `>= 3.11.8` (wersja przypięta w `.python-version`: `3.11.8`)
- [uv](https://github.com/astral-sh/uv) do zarządzania zależnościami
- Docker (do budowy obrazu)
- `gcloud` CLI (do wdrożenia na Cloud Run)

## Uruchomienie lokalne

Z użyciem `uv` (rekomendowane):

```bash
uv sync
uv run uvicorn app:app --host 0.0.0.0 --port 8080
```

Albo klasycznie przez pip:

```bash
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8080
```

Dokumentacja interaktywna (Swagger UI) dostępna pod `http://localhost:8080/docs`.

### Szybki test lokalnie

```bash
curl http://localhost:8080/health
```

## Zależności

Zależności runtime są zarządzane przez `uv` (`pyproject.toml` + `uv.lock`). Plik `requirements.txt` używany przez Docker jest **generowany** z lock-a — po każdej zmianie zależności należy go zregenerować:

```bash
./regenerate_requirements.sh
# uv export --no-hashes --no-emit-project --no-dev -o requirements.txt
```

> ⚠️ Keras używa backendu TensorFlow. Dryf wersji TF/Keras między treningiem a serwowaniem może zepsuć `load_model` — trzymaj się wersji z lock-a.

## Docker

```bash
docker build -t mnist-api .
docker run -p 8080:8080 mnist-api
```

## Wdrożenie na Google Cloud Run

Kroki jednorazowe (świeży projekt GCP):

```bash
./set_project.sh          # gcloud config set project szkolenie-docker-01
./enable_apis.sh          # run, cloudbuild, artifactregistry
./grant_permissions.sh    # rola editor dla domyślnego SA Compute (build z --source)
```

Wdrożenie (build ze źródła przez Cloud Build → Cloud Run):

```bash
./deploy.sh
```

`deploy.sh` wdraża usługę `mnist-api` w regionie `europe-west1` z `--allow-unauthenticated`,
`1Gi` pamięci, `1` CPU, autoskalowaniem `0–10` instancji i timeoutem `60s`.

### Test wdrożonej usługi

`test_request.sh` pobiera URL usługi z Cloud Run, generuje próbkę z testowego zbioru MNIST,
wysyła ją do `/predict` i wypisuje przewidzianą klasę oraz pewność:

```bash
./test_request.sh
```

## Struktura projektu

```text
app.py                      # aplikacja FastAPI
mnist_model.keras           # wytrenowany model
Dockerfile                  # obraz produkcyjny
requirements.txt            # zależności dla Dockera (generowane z uv.lock)
pyproject.toml / uv.lock    # zarządzanie zależnościami (uv)
set_project.sh              # wybór projektu GCP
enable_apis.sh              # włączenie wymaganych API GCP
grant_permissions.sh        # nadanie ról IAM dla Cloud Build
deploy.sh                   # wdrożenie na Cloud Run
test_request.sh             # smoke test wdrożonej usługi
regenerate_requirements.sh  # regeneracja requirements.txt z uv.lock
```
