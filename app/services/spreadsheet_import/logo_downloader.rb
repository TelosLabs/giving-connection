require "net/http"
require "uri"
require "stringio"

module SpreadsheetImport
  # Downloads a remote logo from the spreadsheet's "Logo" column and returns an
  # attachable payload ({io:, filename:, content_type:}) or nil.
  #
  # It NEVER raises — a bad logo URL must not abort the import. When it returns
  # nil the caller falls back to the bundled default logo.
  #
  # Robustness the real-world URLs demand:
  #   * follow redirects, including http -> https (open-uri refuses those)
  #   * send a browser User-Agent — Wix/Squarespace/GoDaddy CDNs 403 the default
  #     Ruby agent
  #   * bias the Accept header toward jpeg/png so format-negotiating CDNs (Wix
  #     serves avif otherwise) hand back something ActiveStorage will accept
  #   * reject non-images (e.g. a link to an org's home page returns text/html)
  #   * transcode other real image formats (webp/avif/gif/...) to jpeg, since
  #     Organization only allows image/png and image/jpeg
  class LogoDownloader
    ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/jpg].freeze
    MAX_REDIRECTS = 5
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10
    USER_AGENT =
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ACCEPT = "image/jpeg,image/png,image/webp;q=0.8,image/*;q=0.5,*/*;q=0.1"

    def initialize(url)
      @url = url.to_s.strip
    end

    def call
      return nil if blank_url?

      response = fetch(@url)
      return nil unless response

      body = response.body.to_s
      return nil if body.empty?

      content_type = parse_content_type(response)

      if ALLOWED_CONTENT_TYPES.include?(content_type)
        # Normalize the odd-but-valid "image/jpg" to a canonical jpeg type.
        payload(body, content_type == "image/png" ? "image/png" : "image/jpeg")
      elsif image_content_type?(content_type)
        converted = convert_to_jpeg(body)
        converted ? payload(converted, "image/jpeg") : nil
      else
        Rails.logger.warn "🖼 Logo skipped — not an image (#{content_type.inspect}) at #{@url}"
        nil
      end
    rescue => e
      Rails.logger.warn "🖼 Logo download failed for #{@url}: #{e.class}: #{e.message}"
      nil
    end

    private

    def blank_url?
      @url.blank? || %w[na n/a].include?(@url.downcase)
    end

    def fetch(url, redirects_left = MAX_REDIRECTS)
      uri = URI.parse(url)
      return nil unless uri.is_a?(URI::HTTP) && uri.host.present?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT
      request["Accept"] = ACCEPT

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        return nil if redirects_left <= 0

        location = response["location"]
        return nil if location.blank?

        # Resolve relative redirect targets against the current URL.
        fetch(URI.join(url, location).to_s, redirects_left - 1)
      else
        Rails.logger.warn "🖼 Logo fetch got HTTP #{response.code} for #{url}"
        nil
      end
    end

    def parse_content_type(response)
      response.content_type.to_s.split(";").first.to_s.strip.downcase
    end

    # Treat anything the server labels as an image (webp, avif, gif, tiff, heic,
    # octet-stream masquerading as an image, ...) as convertible. Explicitly
    # non-image types (text/html, application/json) fall through to be skipped.
    def image_content_type?(content_type)
      content_type.start_with?("image/") || content_type == "application/octet-stream"
    end

    def convert_to_jpeg(body)
      image = MiniMagick::Image.read(body)
      image.format("jpeg")
      image.to_blob
    rescue => e
      Rails.logger.warn "🖼 Logo transcode to jpeg failed for #{@url}: #{e.message}"
      nil
    end

    def payload(body, content_type)
      extension = content_type == "image/png" ? "png" : "jpg"
      {
        io: StringIO.new(body),
        filename: "logo.#{extension}",
        content_type: content_type
      }
    end
  end
end
