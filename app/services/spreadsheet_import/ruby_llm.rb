require "ruby_llm"

module SpreadsheetImport
  class RubyLlm
    def self.format_address(raw_address)
      prompt = <<~PROMPT
        Format the following US address string into a structured JSON with keys:
        - address_line1 (remove PO Box if present. If no street address is found, return null)
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
      Respond ONLY with valid JSON, no extra text.
      PROMPT

      chat = RubyLLM.chat
      response = chat.ask(prompt)
      
      content = response.respond_to?(:content) ? response.content : response.output_text
      content = content.gsub(/```json|```/, "").strip

      begin
        JSON.parse(response.content)
      rescue JSON::ParserError
        {error: "Could not parse LLM response", raw_response: response.content}
      end
    end
  end
end
