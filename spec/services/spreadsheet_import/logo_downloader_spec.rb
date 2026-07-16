require "rails_helper"

RSpec.describe SpreadsheetImport::LogoDownloader do
  # Build a fake Net::HTTP response without hitting the network.
  def http_response(code, body: "", content_type: nil, location: nil)
    klass =
      case code.to_i
      when 200 then Net::HTTPOK
      when 301 then Net::HTTPMovedPermanently
      when 302 then Net::HTTPFound
      when 403 then Net::HTTPForbidden
      when 404 then Net::HTTPNotFound
      else Net::HTTPServerError
      end

    response = klass.new("1.1", code.to_s, "")
    allow(response).to receive(:body).and_return(body)
    allow(response).to receive(:content_type).and_return(content_type)
    response["location"] = location if location
    response
  end

  # Stub the whole request cycle, keying responses by request path so redirect
  # chains can be exercised.
  def stub_http(responses_by_path)
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request) do |request|
      key = responses_by_path.keys.find { |k| request.path.include?(k) } || responses_by_path.keys.first
      responses_by_path[key]
    end
  end

  # A real png (the bundled default logo) so content-type handling, transcoding,
  # and attachment are exercised against genuine image bytes.
  def png_bytes
    @png_bytes ||= Rails.root.join("app/assets/images/logo-default1.png").binread
  end

  describe "#call" do
    it "returns nil for a blank url" do
      expect(described_class.new("").call).to be_nil
      expect(described_class.new(nil).call).to be_nil
    end

    it "returns nil for an 'NA' placeholder" do
      expect(described_class.new("NA").call).to be_nil
      expect(described_class.new("n/a").call).to be_nil
    end

    it "returns an attachable payload for a png" do
      stub_http("logo.png" => http_response(200, body: png_bytes, content_type: "image/png"))

      payload = described_class.new("https://example.org/logo.png").call

      expect(payload).to include(content_type: "image/png", filename: "logo.png")
      expect(payload[:io].read).to eq(png_bytes)
    end

    it "passes jpeg through unchanged" do
      stub_http("logo.jpg" => http_response(200, body: "jpegbytes", content_type: "image/jpeg"))

      payload = described_class.new("https://example.org/logo.jpg").call

      expect(payload).to include(content_type: "image/jpeg", filename: "logo.jpg")
    end

    it "transcodes a webp image to jpeg" do
      webp = MiniMagick::Image.read(png_bytes).tap { |i| i.format("webp") }.to_blob
      stub_http("logo.webp" => http_response(200, body: webp, content_type: "image/webp"))

      payload = described_class.new("https://cdn.example.org/logo.webp").call

      expect(payload[:content_type]).to eq("image/jpeg")
      expect(payload[:filename]).to eq("logo.jpg")
      # Verify the bytes really are a jpeg ImageMagick can read back.
      expect(MiniMagick::Image.read(payload[:io].read).type).to eq("JPEG")
    end

    it "returns nil when the url points at an html page, not an image" do
      stub_http("home" => http_response(200, body: "<html></html>", content_type: "text/html"))

      expect(described_class.new("https://example.org/home").call).to be_nil
    end

    it "returns nil on a 403 without raising" do
      stub_http("logo.png" => http_response(403, body: "blocked", content_type: "text/html"))

      expect(described_class.new("https://example.org/logo.png").call).to be_nil
    end

    it "returns nil on a 404 without raising" do
      stub_http("logo.png" => http_response(404, body: "missing", content_type: "text/html"))

      expect(described_class.new("https://example.org/logo.png").call).to be_nil
    end

    it "follows redirects" do
      stub_http(
        "start.png" => http_response(302, location: "https://cdn.example.org/final.png"),
        "final.png" => http_response(200, body: png_bytes, content_type: "image/png")
      )

      payload = described_class.new("https://example.org/start.png").call

      expect(payload).to include(content_type: "image/png")
    end

    it "never raises when the network blows up" do
      allow(Net::HTTP).to receive(:new).and_raise(SocketError, "getaddrinfo failed")

      expect { described_class.new("https://nope.invalid/logo.png").call }.not_to raise_error
      expect(described_class.new("https://nope.invalid/logo.png").call).to be_nil
    end
  end
end
