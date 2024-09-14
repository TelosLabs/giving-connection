class ImageHeicToJpegConverter < ApplicationService
  def initialize(image)
    @image = image
  end

  def convert
    MiniMagick::Image.read(@image).format("jpeg")
  end
end
