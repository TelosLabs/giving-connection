module EventListCard
  class Component < ViewComponent::Base

    include Rails.application.routes.url_helpers
    
    def initialize(admin:, small:, event:, edit_url: nil, view_url: nil)
      @admin = admin
      @event = event
      @small = small
      @edit_url = edit_url
      @view_url = view_url
    end

    private

    attr_reader :event
  end
end