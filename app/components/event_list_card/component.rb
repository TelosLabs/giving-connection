# app/components/event_list_card/component.rb
module EventListCard
    class Component < ViewComponent::Base
      def initialize(event:)
        @event = event
      end
  
      private
  
      attr_reader :event
    end
  end