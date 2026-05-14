# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::EmbeddingClient do
  let(:vector) { Array.new(1024) { 0.1 } }
  let(:base_url) { "http://127.0.0.1:8000" }

  # The persistent-connection refactor (F8) replaced
  #   Net::HTTP.start(host, port, ...) { |http| http.request(req) }
  # with
  #   conn = Net::HTTP.new(host, port); conn.start; conn.request(req)
  # cached per-thread. These specs intercept Net::HTTP.new so every test runs
  # against a deterministic fake connection, and clear the thread-local cache
  # before/after so tests don't leak HTTP state.

  let(:http_conn) do
    conn = instance_double(Net::HTTP)
    allow(conn).to receive(:open_timeout=)
    allow(conn).to receive(:read_timeout=)
    allow(conn).to receive(:use_ssl=)
    allow(conn).to receive(:verify_mode=)
    allow(conn).to receive(:keep_alive_timeout=)
    allow(conn).to receive(:start).and_return(conn)
    allow(conn).to receive(:started?).and_return(true)
    allow(conn).to receive(:finish)
    conn
  end

  def stub_response(body:, success: true)
    klass = success ? Net::HTTPOK : Net::HTTPInternalServerError
    res = instance_double(klass, body: body, code: success ? "200" : "503")
    allow(res).to receive(:is_a?).and_return(false)
    allow(res).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    res
  end

  before do
    Thread.current[:smart_match_embedding_http] = nil
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("EMBEDDING_SERVICE_URL", "http://127.0.0.1:8000").and_return(base_url)
    allow(Net::HTTP).to receive(:new).and_return(http_conn)
  end

  after do
    Thread.current[:smart_match_embedding_http] = nil
  end

  describe ".call" do
    it "returns a vector from the embedding service" do
      allow(http_conn).to receive(:request).and_return(stub_response(body: {vector: vector}.to_json))

      expect(described_class.call(text: "test input")).to eq(vector)
    end

    it "raises EmbeddingUnavailableError on non-success response" do
      allow(http_conn).to receive(:request).and_return(stub_response(body: "", success: false))

      expect {
        described_class.call(text: "test input")
      }.to raise_error(SmartMatch::EmbeddingUnavailableError, /503/)
    end

    it "raises EmbeddingUnavailableError on timeout after retries" do
      allow(http_conn).to receive(:request).and_raise(Timeout::Error)

      expect {
        described_class.call(text: "test input")
      }.to raise_error(SmartMatch::EmbeddingUnavailableError, /unavailable/)
    end

    it "raises EmbeddingUnavailableError on connection refused after retries" do
      allow(http_conn).to receive(:request).and_raise(Errno::ECONNREFUSED)

      expect {
        described_class.call(text: "test input")
      }.to raise_error(SmartMatch::EmbeddingUnavailableError, /unavailable/)
    end

    # Regression sentinel for the parse_vector class-method scoping bug
    # (caller invoked it as an instance method, raised NoMethodError on every
    # real request).
    it "resolves parse_vector via self.class from the instance #call" do
      allow(http_conn).to receive(:request).and_return(stub_response(body: {vector: vector}.to_json))

      instance = described_class.new(text: "scope check")

      expect(instance.call).to eq(vector)
    end
  end

  describe ".embed_batch" do
    it "returns vectors for a batch of texts" do
      texts = ["text one", "text two"]
      vectors = [vector, vector]
      allow(http_conn).to receive(:request).and_return(stub_response(body: {vectors: vectors}.to_json))

      result = described_class.embed_batch(texts: texts)

      expect(result.size).to eq(2)
      expect(result.first.size).to eq(1024)
    end
  end

  # Persistent keep-alive regression sentinel: two consecutive calls on the
  # same thread must share one Net::HTTP instance. If anyone removes the
  # thread-local cache, this test fails because Net::HTTP.new is called twice.
  describe "persistent HTTP connection" do
    it "reuses the same Net::HTTP instance across calls on the same thread" do
      Thread.current[:smart_match_embedding_http] = nil
      allow(http_conn).to receive(:request).and_return(stub_response(body: {vector: vector}.to_json))

      described_class.call(text: "first")
      described_class.call(text: "second")

      expect(Net::HTTP).to have_received(:new).once
    end
  end
end
