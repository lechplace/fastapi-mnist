#!/usr/bin/env bash
# Odpytanie wdrożonej usługi mnist-api przykładową cyfrą z MNIST.
# Pobiera URL z Cloud Run, generuje świeżą próbkę i wysyła do /predict.
set -euo pipefail

REGION=europe-west1
SERVICE=mnist-api

# 1) URL usługi prosto z Cloud Run (bez hardkodowania)
URL=$(gcloud run services describe "$SERVICE" --region "$REGION" --format="value(status.url)")
echo "Usługa: $URL"

# 2) Wygeneruj przykładowy request: pierwsza cyfra ze zbioru testowego MNIST,
#    znormalizowana do [0,1], zapisana jako {"image": [[...28...], ...28... ]}
uv run python - <<'PY'
import json, keras
(_, _), (x_test, y_test) = keras.datasets.mnist.load_data()
img = (x_test[0].astype("float32") / 255.0)        # shape (28, 28)
json.dump({"image": img.tolist()}, open("/tmp/sample_request.json", "w"))
print(f"Prawdziwa etykieta próbki: {int(y_test[0])}")
PY

# 3) Smoke test + predykcja
echo "--- GET /health ---"
curl -s "$URL/health"; echo

echo "--- POST /predict ---"
curl -s -X POST "$URL/predict" \
    -H "Content-Type: application/json" \
    -d @/tmp/sample_request.json \
| python3 -c "import sys,json; d=json.load(sys.stdin); print('predicted_class:', d['predicted_class']); print('confidence: %.4f' % max(d['probabilities']))"
