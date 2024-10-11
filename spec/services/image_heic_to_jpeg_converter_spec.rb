require "rails_helper"

RSpec.describe ImageHeicToJpegConverter, type: :service do
  let(:heic_image_path) { Rails.root.join("spec/fixtures/test_image.HEIC") }

  subject { described_class.new(heic_image_path) }

  describe "#convert" do
    it "converts heic image to jpeg" do
      expect(MiniMagick::Image.open(heic_image_path).type).to eq("HEIC")

      converted_image = subject.convert

      expect(converted_image).to be_a(MiniMagick::Image)
      expect(converted_image.mime_type).to eq("image/jpeg")
    end
  end
end
