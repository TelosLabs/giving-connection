require "ruby_llm"

openai_api_key = Rails.application.credentials.dig(:ruby_llm, :openai)
gemini_api_key = Rails.application.credentials.dig(:ruby_llm, :gemini)

RubyLLM.configure do |config|
  config.openai_api_key = openai_api_key
  config.gemini_api_key = gemini_api_key
end
