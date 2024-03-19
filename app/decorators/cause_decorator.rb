class CauseDecorator < ApplicationDecorator
  delegate_all

  def svg_file_name
    name.downcase
      .delete("&")
      .split(" ")
      .join("_")
      .tr("-", "_") <<
      ".svg"
  end
end
