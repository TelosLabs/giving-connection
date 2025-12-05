class Newsletter < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  before_create :generate_verification_token
  
  scope :verified_not_added, -> { where(verified: true, added: false) }
  scope :unverified, -> { where(verified: false) }
  
  def verify!
    update(verified: true)
  end
  
  def mark_as_added!
    update(added: true)
  end
  
  private
  
  def generate_verification_token
    self.verification_token = SecureRandom.urlsafe_base64(32)
  end
end