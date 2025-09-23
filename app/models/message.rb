# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id                   :bigint           not null, primary key
#  name                 :string           not null
#  email                :string           not null
#  phone                :string
#  subject              :string
#  organization_name    :string
#  organization_website :string
#  organization_ein     :string
#  content              :text
#  profile_admin_name   :string           not null
#  profile_admin_email  :string           not null
#
class Message < ActiveRecord::Base
  attr_accessor :form_definition

  validates :name, presence: true, format: {without: /https?:\/\/|www\.|\.com|\.org|\.net|\.edu|\.gov|\.io|\.co/i, message: "cannot contain URLs or web addresses"}
  validates :email, format: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :content, length: {maximum: 2000, message: "is too long (maximum is 2000 characters)"}

  validate :no_excessive_links_in_content
  validate :name_appears_human
  validate :email_appears_legitimate
  validate :phone_appears_legitimate
  validate :content_appears_legitimate

  private

  def no_excessive_links_in_content
    return if content.blank?

    url_count = content.scan(/https?:\/\/|www\.|\.com|\.org|\.net|\.edu|\.gov|\.io|\.co/i).length
    if url_count > 2
      errors.add(:content, "contains too many links")
    end
  end

  def name_appears_human
    return if name.blank?

    # Check for repetitive characters (like "aaaa" or "1111")
    if name.match?(/(.)\1{3,}/)
      errors.add(:name, "appears to be invalid")
    end

    # Check for overly long names (likely spam)
    if name.length > 50
      errors.add(:name, "is too long")
    end

    # Check for names that are all numbers or special characters
    if name.match?(/^[^a-zA-Z\s]+$/)
      errors.add(:name, "must contain letters")
    end

    # Check for excessive numbers (more than 30% of characters are numbers)
    number_count = name.scan(/\d/).length
    if number_count > 0 && (number_count.to_f / name.length) > 0.3
      errors.add(:name, "contains too many numbers")
    end

    # Check for phone number patterns in name
    if name.match?(/\d{3}[-.\s]?\d{3}[-.\s]?\d{4}/)
      errors.add(:name, "appears to be a phone number")
    end
  end

  def email_appears_legitimate
    return if email.blank?

    # Block common spam email patterns
    spam_domains = %w[
      10minutemail.com tempmail.org guerrillamail.com mailinator.com
      throwaway.email temp-mail.org dispostable.com yopmail.com
    ]

    domain = email.split("@").last&.downcase
    if spam_domains.include?(domain)
      errors.add(:email, "appears to be from a temporary email service")
    end

    # Block emails with excessive numbers
    local_part = email.split("@").first
    if local_part && local_part.scan(/\d/).length > local_part.length * 0.5
      errors.add(:email, "contains too many numbers")
    end

    # Block emails with repetitive patterns
    if email.match?(/(.)\1{4,}/)
      errors.add(:email, "contains repetitive patterns")
    end
  end

  def phone_appears_legitimate
    return if phone.blank?

    # Remove common formatting to analyze
    clean_phone = phone.gsub(/[-.\s()]/, "")

    # Check for repetitive numbers
    if clean_phone.match?(/(.)\1{4,}/)
      errors.add(:phone, "contains repetitive patterns")
    end

    # Check for obviously fake patterns
    fake_patterns = %w[1111111111 0000000000 1234567890 0123456789]
    if fake_patterns.include?(clean_phone)
      errors.add(:phone, "appears to be invalid")
    end

    # Check length (US phone numbers)
    if clean_phone.match?(/^\d+$/) && (clean_phone.length < 10 || clean_phone.length > 11)
      errors.add(:phone, "appears to be invalid length")
    end
  end

  def content_appears_legitimate
    return if content.blank?

    # Check for excessive repetitive characters or words
    if content.match?(/(.{3,})\s*\1\s*\1/) || content.match?(/(.)\1{6,}/)
      errors.add(:content, "contains repetitive patterns")
    end

    # Check for excessive capitalization (more than 50% caps)
    caps_count = content.scan(/[A-Z]/).length
    letter_count = content.scan(/[A-Za-z]/).length
    if letter_count > 0 && (caps_count.to_f / letter_count) > 0.5
      errors.add(:content, "contains excessive capitalization")
    end

    # Check for common spam phrases
    spam_phrases = [
      "make money fast", "click here", "buy now", "free money",
      "guaranteed income", "work from home", "no experience necessary",
      "limited time offer", "act now", "call now"
    ]

    content_downcase = content.downcase
    spam_phrases.each do |phrase|
      if content_downcase.include?(phrase)
        errors.add(:content, "contains promotional language")
        break
      end
    end

    # Check for excessive special characters
    special_chars = content.scan(/[!@#$%^&*()_+={}|\\:";'<>?,.]/).length
    if content.length > 0 && (special_chars.to_f / content.length) > 0.2
      errors.add(:content, "contains too many special characters")
    end
  end
end
