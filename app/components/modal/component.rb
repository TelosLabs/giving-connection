class Modal::Component < ApplicationViewComponent
  def initialize(options: {})
    @options = options
  end

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
