namespace :images do
  desc "Convert existing HEIC images to JPEG"
  task convert_heic_to_jpeg: :environment do
    Location.with_images.find_each do |location|
      location.images.each do |image|
        if image.blob.content_type == "image/heic"
          converted_image = ImageHeicToJpegConverter.new(image).convert
          filename = File.basename(image.filename.to_s, ".HEIC")
          if location.images.attach(
            io: File.open(converted_image.path),
            filename: "#{filename}.jpeg",
            content_type: "image/jpeg"
          )
            image.purge
            Rails.logger.info "Converted #{filename}.HEIC to jpeg for Location ID: #{location.id}"
          else
            Rails.logger.error "Failed to attach converted image for Location ID: #{location.id}, Image ID: #{image.id}"
          end
        end
      end
    end
  end
end
