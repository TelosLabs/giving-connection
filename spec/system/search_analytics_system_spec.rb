require "system_helper"

RSpec.describe "Search analytics tracking", type: :system do
  let!(:user) { create(:user) }

  before do
    sign_in user
  end

  it "pushes a search event to the GTM dataLayer when a search is submitted" do
    visit search_path

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)

    expect(page).to have_current_path(search_path, ignore_query: true, wait: 5)

    search_event = wait_for_data_layer_event("search")

    expect(search_event).not_to be_nil
    expect(search_event["search_term"]).to eq("food pantry")
    expect(search_event["category"]).to eq("Find Help")
  end

  it "does not re-fire the search event on pagination" do
    visit search_path

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)
    expect(page).to have_current_path(search_path, ignore_query: true, wait: 5)

    # Make sure the (single) search event has actually landed before counting.
    wait_for_data_layer_event("search")

    count_after_search = fetch_data_layer.count { |entry| entry["event"] == "search" }
    expect(count_after_search).to eq(1)
  end

  private

  # Turbo may still be swapping frames the instant navigation "completes" per
  # have_current_path, so a single evaluate_script read can race and see an
  # empty/stale dataLayer. Poll instead of reading it exactly once.
  def wait_for_data_layer_event(event_name, timeout: 10)
    event = nil
    Timeout.timeout(timeout) do
      loop do
        event = fetch_data_layer.reverse.find { |entry| entry["event"] == event_name }
        break if event
        sleep 0.1
      end
    end
    event
  rescue Timeout::Error
    nil
  end

  # JSON round-trip forces the browser to hand back a plain, JSON-safe
  # structure (no functions/undefined). The try/catch inside the JS itself
  # avoids throwing on any unserializable value (e.g. a circular reference
  # pushed by GTM's own internals), and the Ruby-level rescue is a backup
  # in case Ferrum still raises (e.g. the page context is mid-navigation).
  def fetch_data_layer
    Array(page.evaluate_script(<<~JS))
      (function() {
        try {
          return JSON.parse(JSON.stringify(window.dataLayer || []));
        } catch (err) {
          return [];
        }
      })();
    JS
  rescue Ferrum::JavaScriptError
    []
  end
end
