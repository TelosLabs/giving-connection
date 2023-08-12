class Modal::Component < ApplicationViewComponent
  def initialize(options: {})
    @options = options
  end

  renders_one :footer

  attr_reader :results

  def options
    merge_hashes(
      {
        class:  "",
        src:    "",
        id:     "modal",
        target: ""
      },
      @options
    )
  end
end