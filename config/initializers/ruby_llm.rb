require "ruby_llm"

openai_key = Rails.application.credentials.dig(:openai, :api_key)
raise "Missing api key" unless openai_key

RubyLLM.configure do |config|
  config.openai_api_key = openai_key
end
