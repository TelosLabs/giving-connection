# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::EmbeddingClient do
  let(:vector) { Array.new(1024) { 0.1 } }
  let(:base_url) { "http://127.0.0.1:8000" }
  let(:success_response) { instance_double(Net::HTTPOK, body: {vector: vector}.to_json, is_a?: true) }
  let(:error_response) { instance_double(Net::HTTPInternalServerError, code: "503", is_a?: false) }

  before do
    allow(ENV).to receive(:fetch).with("EMBEDDING_SERVICE_URL", "http://127.0.0.1:8000").and_return(base_url)
    allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
  end

  describe ".call" do
    it "returns a vector from the embedding service" do
      allow(Net::HTTP).to receive(:start).and_return(success_response)

      result = described_class.call(text: "test input")

      expect(result).to eq(vector)
    end

    it "raises EmbeddingUnavailableError on non-success response" do
      allow(Net::HTTP).to receive(:start).and_return(error_response)

      expect {
        described_class.call(text: "test input")
      }.to raise_error(SmartMatch::EmbeddingUnavailableError, /503/)
    end

    it "raises EmbeddingUnavailableError on timeout after retries" do
      allow(Net::HTTP).to receive(:start).and_raise(Timeout::Error)

      expect {
        described_class.call(text: "test input")
      }.to raise_error(SmartMatch::EmbeddingUnavailableError, /unavailable/)
    end

    it "raises EmbeddingUnavailableError on connection refused after retries" do
      allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)

      expect {
        described_class.call(text: "test input")
      }.to raise_error(SmartMatch::EmbeddingUnavailableError, /unavailable/)
    end
  end

  describe ".embed_batch" do
    it "returns vectors for a batch of texts" do
      texts = ["text one", "text two"]
      vectors = [vector, vector]
      batch_response = instance_double(Net::HTTPOK, body: {vectors: vectors}.to_json)
      allow(batch_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(Net::HTTP).to receive(:start).and_return(batch_response)

      result = described_class.embed_batch(texts: texts)

      expect(result.size).to eq(2)
      expect(result.first.size).to eq(1024)
    end
  end
end
