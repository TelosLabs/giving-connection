# Embedding Service

FastAPI service that generates 1024-dimensional text embeddings using [BAAI/bge-large-en-v1.5](https://huggingface.co/BAAI/bge-large-en-v1.5).

Used by the Smart Match engine to embed organization descriptions and quiz answers for cosine similarity matching.

## Setup

### Requirements
- Python 3.11+ (install via `brew install python@3.11` on Mac)

### Install

```bash
cd embedding-service

# Create virtual environment with Python 3.11
python3.11 -m venv venv

# Install PyTorch first (from the official index — PyPI doesn't have all builds)
venv/bin/pip install torch --index-url https://download.pytorch.org/whl/cpu

# Install remaining dependencies
venv/bin/pip install -r requirements.txt
```

### Start the service

```bash
venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
```

The first start downloads the BAAI/bge-large-en-v1.5 model (~1.3 GB) to `~/.cache/huggingface/`. Subsequent starts are fast.

Health check: http://127.0.0.1:8000/health

## After starting the service

Generate embeddings for all organizations (run from the Rails root):

```bash
bin/rails runner "SmartMatch::EmbedAllOrganizationsJob.perform_now"
```

This only needs to be run once, or whenever new organizations are added/updated.
