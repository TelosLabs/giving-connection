require "administrate/field/active_storage"

class ImageUploadField < Administrate::Field::ActiveStorage
  def to_s
    data
  end
end
