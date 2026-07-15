require "rails_helper"

RSpec.describe LocationAutocomplete, type: :service do
  # Fake Places response body (OK) with a trailing-country description to prove
  # the label formatting.
  def ok_body(predictions)
    { "status" => "OK", "predictions" => predictions }.to_json
  end

  def http_response(body)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    allow(response).to receive(:body).and_return(body)
    response
  end

  before do
    # Keep a key present regardless of the CI credentials setup.
    allow_any_instance_of(described_class).to receive(:api_key).and_return("test-key")
  end

  it "returns formatted predictions on an OK response" do
    body = ok_body([
      { "description" => "Nashville, TN, USA", "place_id" => "p1" },
      { "description" => "Nashua, NH, USA", "place_id" => "p2" }
    ])
    allow_any_instance_of(Net::HTTP).to receive(:get).and_return(http_response(body))

    result = described_class.call("nash")

    expect(result).to eq([
      { description: "Nashville, TN", place_id: "p1" },
      { description: "Nashua, NH", place_id: "p2" }
    ])
  end

  it "caps results at MAX_RESULTS" do
    predictions = (1..10).map { |i| { "description" => "City #{i}, TN, USA", "place_id" => "p#{i}" } }
    allow_any_instance_of(Net::HTTP).to receive(:get).and_return(http_response(ok_body(predictions)))

    expect(described_class.call("city").size).to eq(described_class::MAX_RESULTS)
  end

  it "returns [] on ZERO_RESULTS" do
    allow_any_instance_of(Net::HTTP).to receive(:get)
      .and_return(http_response({ "status" => "ZERO_RESULTS", "predictions" => [] }.to_json))

    expect(described_class.call("zzzzz")).to eq([])
  end

  it "returns [] and logs on a non-OK error status (e.g. Places not enabled)" do
    allow_any_instance_of(Net::HTTP).to receive(:get)
      .and_return(http_response({ "status" => "REQUEST_DENIED", "error_message" => "denied" }.to_json))
    expect(Rails.logger).to receive(:warn).with(/non-OK status 'REQUEST_DENIED'/)

    expect(described_class.call("nash")).to eq([])
  end

  it "returns [] without calling the API when the query is too short" do
    expect_any_instance_of(Net::HTTP).not_to receive(:get)

    expect(described_class.call("n")).to eq([])
  end

  it "returns [] and never raises when the HTTP call blows up" do
    allow_any_instance_of(Net::HTTP).to receive(:get).and_raise(SocketError.new("boom"))

    expect { @result = described_class.call("nash") }.not_to raise_error
    expect(@result).to eq([])
  end
end
