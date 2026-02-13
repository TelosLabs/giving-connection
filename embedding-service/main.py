from fastapi import FastAPI

app = FastAPI(title="GivingConnection Embedding Service")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/embed")
def embed(payload: dict):
    """Placeholder endpoint for generating text embeddings.

    Expects: {"text": "some text to embed"}
    Returns: {"vector": [0.0, ...]}  (1024 dimensions)
    """
    text = payload.get("text", "")
    # Placeholder: return a zero vector until model is integrated
    return {"vector": [0.0] * 1024}
