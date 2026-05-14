def test_embed_returns_1024_dim_vector(client):
    response = client.post("/embed", json={"text": "hello world"})

    assert response.status_code == 200
    body = response.json()
    assert "vector" in body
    assert isinstance(body["vector"], list)
    assert len(body["vector"]) == 1024
    assert all(isinstance(v, float) for v in body["vector"])


def test_embed_missing_text_returns_422(client):
    response = client.post("/embed", json={})

    assert response.status_code == 422


def test_embed_empty_body_returns_422(client):
    response = client.post("/embed", content=b"")

    assert response.status_code == 422


def test_embed_returns_503_when_model_not_loaded(client_unloaded):
    response = client_unloaded.post("/embed", json={"text": "hello"})

    assert response.status_code == 503
    assert response.json()["detail"] == "Model not loaded"
