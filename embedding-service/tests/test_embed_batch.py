def test_embed_batch_returns_n_vectors(client):
    texts = ["alpha", "beta", "gamma"]
    response = client.post("/embed_batch", json={"texts": texts})

    assert response.status_code == 200
    body = response.json()
    assert "vectors" in body
    assert len(body["vectors"]) == len(texts)
    for vec in body["vectors"]:
        assert isinstance(vec, list)
        assert len(vec) == 1024


def test_embed_batch_with_empty_list_returns_empty_vectors(client):
    response = client.post("/embed_batch", json={"texts": []})

    assert response.status_code == 200
    assert response.json() == {"vectors": []}


def test_embed_batch_over_max_size_returns_422(client):
    texts = [f"text-{i}" for i in range(65)]
    response = client.post("/embed_batch", json={"texts": texts})

    assert response.status_code == 422


def test_embed_batch_returns_503_when_model_not_loaded(client_unloaded):
    response = client_unloaded.post("/embed_batch", json={"texts": ["hello"]})

    assert response.status_code == 503
    assert response.json()["detail"] == "Model not loaded"
