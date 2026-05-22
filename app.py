"""Mini API dla modelu MNIST.

Uruchomienie lokalnie:
    pip install fastapi uvicorn keras numpy
    uvicorn app:app --host 0.0.0.0 --port 8080

Test:
    curl -X POST http://localhost:8080/predict \\
        -H "Content-Type: application/json" \\
        -d '{"image": [[0.0, 0.1, ...]]}'  # 28x28 floatów w [0, 1]
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import keras
import numpy as np

app = FastAPI(title="MNIST Classifier API", version="1.0")

# Model wczytywany RAZ przy starcie aplikacji (nie przy każdym requeście!)
model = keras.models.load_model('mnist_model.keras')


class PredictRequest(BaseModel):
    image: List[List[float]]  # 28x28 floatów w [0, 1]


class PredictResponse(BaseModel):
    predicted_class: int
    probabilities: List[float]


@app.get("/")
def root():
    return {"status": "ok", "model": "MNIST classifier", "version": "1.0"}


@app.get("/health")
def health():
    """Endpoint zdrowia dla load balancerów i Kubernetes."""
    return {"status": "healthy"}


@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    img = np.array(req.image, dtype=np.float32)
    if img.shape != (28, 28):
        raise HTTPException(status_code=400, detail=f"Oczekiwano shape (28, 28), dostałem {img.shape}")
    preds = model.predict(img[np.newaxis, ...], verbose=0)[0]
    return PredictResponse(
        predicted_class=int(preds.argmax()),
        probabilities=preds.tolist(),
    )
