"""Shared pytest fixtures for the embedding-service test suite.

The real BGE model (~1.3 GB) is never loaded in tests. Instead we patch
`main.SentenceTransformer` so the lifespan handler installs a deterministic
MagicMock as the module-level `model` global.
"""

from unittest.mock import MagicMock, patch

import numpy as np
import pytest
from fastapi.testclient import TestClient

import main


@pytest.fixture
def mock_model():
    """A MagicMock standing in for a loaded SentenceTransformer.

    - `.encode(texts, ...)` returns a numpy array shaped (len(texts), 1024).
    - `.tokenizer.encode(text, ...)` returns a small token-id list so the
      truncation loop in `main._encode` has something to feed back into
      `.tokenizer.decode`, which echoes the original text.
    """
    m = MagicMock()

    def fake_encode(texts, **_kwargs):
        # `texts` may be a list or a single string; main._encode always passes
        # a list, so handle both defensively.
        if isinstance(texts, str):
            n = 1
        else:
            n = len(texts)
        return np.zeros((n, 1024), dtype=np.float32)

    m.encode.side_effect = fake_encode

    # Tokenizer stubs. main._encode does:
    #   tokens = tokenizer.encode(text, ...)
    #   tokenizer.decode(tokens, skip_special_tokens=True)
    # We don't care about the token-id values, only that decode round-trips
    # the original text so the assertions downstream remain stable.
    m.tokenizer = MagicMock()
    m.tokenizer.encode.side_effect = lambda text, **_kwargs: [0, 1, 2]
    # Capture the most recent text passed to tokenizer.encode and return it
    # from decode, mimicking a no-op truncation.
    state = {"last_text": ""}

    def fake_tok_encode(text, **_kwargs):
        state["last_text"] = text
        return [0, 1, 2]

    def fake_tok_decode(_tokens, **_kwargs):
        return state["last_text"]

    m.tokenizer.encode.side_effect = fake_tok_encode
    m.tokenizer.decode.side_effect = fake_tok_decode

    return m


@pytest.fixture
def client(mock_model):
    """A TestClient with the lifespan executed and `main.model` set to mock_model.

    We patch `main.SentenceTransformer` so the lifespan's call to
    `SentenceTransformer(MODEL_NAME)` returns our mock. Entering TestClient as a
    context manager triggers FastAPI's lifespan handler.
    """
    with patch("main.SentenceTransformer", return_value=mock_model):
        with TestClient(main.app) as c:
            yield c


@pytest.fixture
def client_unloaded():
    """A TestClient where `main.model` is None (model not loaded).

    We do NOT enter TestClient as a context manager so the lifespan never runs.
    We also explicitly set `main.model = None` to neutralize any prior state.
    """
    main.model = None
    yield TestClient(main.app)
    main.model = None
