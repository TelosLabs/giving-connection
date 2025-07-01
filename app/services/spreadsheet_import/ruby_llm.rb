require 'ruby_llm'

module SpreadsheetImport
  class RubyLlm

    def self.format_address(raw_address)
      prompt = <<~PROMPT
        Format the following US address string into a structured JSON with keys:
        - address_line1 (remove PO Box if present)
        - city
        - state
        - zip
        - country (always return "USA")

        Input:
        "#{raw_address}"

        Output format:
        {
          "address_line1": "...",
          "city": "...",
          "state": "...",
          "zip": "...",
          "country": "USA"
        }
      PROMPT

      chat = RubyLLM.chat
      response = chat.ask(prompt)

      begin
        parsed = JSON.parse(response.content)
        [
          parsed["address_line1"],
          parsed["city"],
          parsed["state"],
          parsed["zip"],
          parsed["country"]
        ].compact.join(", ")
      rescue JSON::ParserError
        { error: "Could not parse LLM response", raw_response: response.content }
      end
    end
  end
end
