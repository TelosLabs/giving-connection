require "ruby_llm"

api_key = Rails.application.credentials.dig(:ruby_llm, :gemini)
raise "Missing api key" unless api_key

RubyLLM.configure do |config|
  config.provider = :google_gemini
  config.api_key = api_key
end
