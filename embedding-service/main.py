from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from sentence_transformers import SentenceTransformer

model: SentenceTransformer | None = None

MODEL_NAME = "BAAI/bge-large-en-v1.5"
MAX_TOKENS = 512
MAX_BATCH_SIZE = 64


@asynccontextmanager
async def lifespan(app: FastAPI):
    global model
    model = SentenceTransformer(MODEL_NAME)
    model.max_seq_length = MAX_TOKENS
    yield
    model = None


app = FastAPI(title="GivingConnection Embedding Service", lifespan=lifespan)


class EmbedRequest(BaseModel):
    text: str


class EmbedResponse(BaseModel):
    vector: list[float]


class EmbedBatchRequest(BaseModel):
    texts: list[str] = Field(..., max_length=MAX_BATCH_SIZE)


class EmbedBatchResponse(BaseModel):
    vectors: list[list[float]]


def _encode(texts: list[str]) -> list[list[float]]:
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    tokenizer = model.tokenizer
    truncated = []
    for text in texts:
        tokens = tokenizer.encode(text, add_special_tokens=True, truncation=True, max_length=MAX_TOKENS)
        truncated.append(tokenizer.decode(tokens, skip_special_tokens=True))

    embeddings = model.encode(truncated, normalize_embeddings=True)
    return [vec.tolist() for vec in embeddings]


@app.get("/health")
def health():
    return {
        "status": "ok" if model is not None else "loading",
        "model": MODEL_NAME,
        "model_loaded": model is not None,
    }


@app.post("/embed", response_model=EmbedResponse)
def embed(payload: EmbedRequest):
    vectors = _encode([payload.text])
    return EmbedResponse(vector=vectors[0])


@app.post("/embed_batch", response_model=EmbedBatchResponse)
def embed_batch(payload: EmbedBatchRequest):
    if len(payload.texts) == 0:
        return EmbedBatchResponse(vectors=[])

    vectors = _encode(payload.texts)
    return EmbedBatchResponse(vectors=vectors)
