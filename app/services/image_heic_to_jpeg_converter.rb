class ImageHeicToJpegConverter < ApplicationService
  def initialize(image)
    @image = image
  end

  def convert
    MiniMagick::Image.open(@image).format("jpeg")
  end
end
