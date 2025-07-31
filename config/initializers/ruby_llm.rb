require "ruby_llm"

api_key = Rails.application.credentials.dig(:ruby_llm, :gemini)
raise "Missing api key" unless api_key

client = RubyLLM::GoogleGemini.new(api_key: api_key)

RubyLLM.configure do |config|
  config.default_client = client
end
