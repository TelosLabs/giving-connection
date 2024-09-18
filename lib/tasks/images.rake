namespace :images do
  desc "Convert existing HEIC images to JPEG"
  task convert_heic_to_jpeg: :environment do
    Location.with_images.find_each do |location|
      location.images.each do |image|
        if image.blob.content_type == "image/heic"
          converted_image = ImageHeicToJpegConverter.new(image).convert
          filename = File.basename(image.filename.to_s, ".HEIC")
          image.purge
          if location.images.attach(io: File.open(converted_image.path), filename: "#{filename}.jpeg", content_type: "image/jpeg")
            puts "Converted #{filename}.HEIC to #{filename}.jpeg"
          else
            puts "Failed to convert #{filename}.HEIC to #{filename}.jpeg"
          end
        end
      end
    end
  end
end
