class SelectMultiple::Component < ViewComponent::Base
  def initialize(name: ,items: {}, value: '')
    @name = name
    @items = items
    @value = value
  end

  def options
    {
      class:' block h-46px mt-1 w-full py-3.5 px-4 border-grey-5 rounded-6px text-base text-grey-3 focus:ring-blue-medium focus:border-blue-medium',
      type: 'text',
      name: :causes,
      id: :causes,
      data: {
        controller: 'controller',
      }
    }
  end
end