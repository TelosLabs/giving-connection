def test_health_returns_503_when_model_not_loaded(client_unloaded):
    response = client_unloaded.get("/health")

    assert response.status_code == 503
    body = response.json()
    assert body["status"] == "loading"
    assert body["model_loaded"] is False
    assert body["model"] == "BAAI/bge-large-en-v1.5"
    assert body["embedding_dim"] == 1024


def test_health_returns_200_when_model_loaded(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "model": "BAAI/bge-large-en-v1.5",
        "model_loaded": True,
        "embedding_dim": 1024,
    }
