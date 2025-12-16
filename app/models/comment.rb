class Comment < ApplicationRecord
  belongs_to :blog
  belongs_to :user

  validates :body, presence: true, length: {minimum: 1, maximum: 2000, too_long: "is too long (maximum is 2000 characters)"}

  before_validation :sanitize_body

  private

  def sanitize_body
    return if body.blank?

    self.body = ActionController::Base.helpers.sanitize(body, tags: [], attributes: []).strip

    self.body = body.squeeze(" ").strip
  end
end
