from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Response
from pydantic import BaseModel, Field, field_validator
from sentence_transformers import SentenceTransformer

model: SentenceTransformer | None = None

MODEL_NAME = "BAAI/bge-large-en-v1.5"
EMBEDDING_DIM = 1024
MAX_TOKENS = 512
MAX_BATCH_SIZE = 64
# Upper bound on characters per text. The model only consumes MAX_TOKENS (~512)
# tokens and truncates the rest, so anything beyond a few thousand chars is
# pure waste. Bound the input BEFORE it reaches the tokenizer so a single
# multi-megabyte string can't burn CPU/memory ahead of truncation. Generous
# relative to MAX_TOKENS (worst-case ~1 char/token) to never clip real text.
MAX_TEXT_CHARS = 20_000


@asynccontextmanager
async def lifespan(app: FastAPI):
    global model
    # Load BGE synchronously inside the async lifespan so /health stays
    # in the "loading" state for the full load. Kamal's healthcheck
    # must wait for /health to return 200 before swinging traffic in --
    # serving 503 here is the gate.
    model = SentenceTransformer(MODEL_NAME)
    model.max_seq_length = MAX_TOKENS
    yield
    model = None


app = FastAPI(title="GivingConnection Embedding Service", lifespan=lifespan)


class EmbedRequest(BaseModel):
    text: str = Field(..., max_length=MAX_TEXT_CHARS)


class EmbedResponse(BaseModel):
    vector: list[float]


class EmbedBatchRequest(BaseModel):
    texts: list[str] = Field(..., max_length=MAX_BATCH_SIZE)

    # `max_length` above bounds the item COUNT; this validator bounds each
    # item's SIZE so one oversized entry can't slip through the batch
    # guardrail. A violation raises ValueError, which FastAPI surfaces as 422.
    @field_validator("texts")
    @classmethod
    def _bound_text_sizes(cls, texts: list[str]) -> list[str]:
        for text in texts:
            if len(text) > MAX_TEXT_CHARS:
                raise ValueError(
                    f"each text must be at most {MAX_TEXT_CHARS} characters"
                )
        return texts


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
def health(response: Response):
    loaded = model is not None
    if not loaded:
        # Kamal/Compose healthchecks treat 2xx as healthy; 503 here keeps the
        # container "starting" until the model finishes loading so traffic is
        # not routed to a node that would 503 every /embed call.
        response.status_code = 503
    return {
        "status": "ok" if loaded else "loading",
        "model": MODEL_NAME,
        "model_loaded": loaded,
        "embedding_dim": EMBEDDING_DIM,
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
