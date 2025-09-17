require "ruby_llm"

module SpreadsheetImport
  class RubyLlm
    def self.format_address(raw_address)
      prompt = <<~PROMPT
          Format the following US address string into a structured JSON with keys.:
          - address_line1 (remove PO Box if present. remove Apt if present. remove Suite if present. If no street address is found, return null)
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

      chat = RubyLLM.chat(model: "gemini-2.0-flash")
      response = chat.ask(prompt)

      text =
        if response.respond_to?(:content) then response.content.to_s
        elsif response.respond_to?(:output_text) then response.output_text.to_s
        else
          response.to_s
        end

      cleaned = text.gsub(/```json|```/i, "").strip
      json_str = cleaned[/\{.*\}/m] || cleaned

      begin
        data = JSON.parse(json_str)

        data["country"] = "USA"
        %w[address_line1 city state zip country].each { |k| data[k] = nil unless data.key?(k) }

        data
      rescue JSON::ParserError
        {error: "Could not parse LLM response", raw_response: response.content}
      end
    end
  end
end
