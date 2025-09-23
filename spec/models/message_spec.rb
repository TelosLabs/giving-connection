require "rails_helper"

RSpec.describe Message, type: :model do
  describe "validations" do
    subject { create(:message) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to_not allow_value("invalid_email").for(:email) }

    describe "name validation" do
      it "rejects names containing URLs" do
        expect(build(:message, name: "John http://spam.com")).to_not be_valid
        expect(build(:message, name: "Jane www.spam.com")).to_not be_valid
        expect(build(:message, name: "Bob spam.com")).to_not be_valid
      end

      it "rejects names with excessive repetitive characters" do
        expect(build(:message, name: "aaaaaaa")).to_not be_valid
      end

      it "rejects overly long names" do
        long_name = "a" * 51
        expect(build(:message, name: long_name)).to_not be_valid
      end

      it "rejects names with only numbers or special characters" do
        expect(build(:message, name: "12345")).to_not be_valid
        expect(build(:message, name: "@#$%")).to_not be_valid
      end

      it "rejects names with excessive numbers" do
        expect(build(:message, name: "John123456")).to_not be_valid
        expect(build(:message, name: "Test999888")).to_not be_valid
      end

      it "rejects phone numbers in name field" do
        expect(build(:message, name: "555-123-4567")).to_not be_valid
        expect(build(:message, name: "555.123.4567")).to_not be_valid
        expect(build(:message, name: "5551234567")).to_not be_valid
      end

      it "accepts valid names" do
        expect(build(:message, name: "John Smith")).to be_valid
        expect(build(:message, name: "María García")).to be_valid
      end
    end

    describe "email validation" do
      it "rejects temporary email services" do
        expect(build(:message, email: "test@10minutemail.com")).to_not be_valid
        expect(build(:message, email: "user@tempmail.org")).to_not be_valid
        expect(build(:message, email: "spam@mailinator.com")).to_not be_valid
      end

      it "rejects emails with excessive numbers" do
        expect(build(:message, email: "12345@example.com")).to_not be_valid
        expect(build(:message, email: "user123456@test.com")).to_not be_valid
      end

      it "rejects emails with repetitive patterns" do
        expect(build(:message, email: "aaaaa@example.com")).to_not be_valid
        expect(build(:message, email: "user11111@test.com")).to_not be_valid
      end

      it "accepts legitimate emails" do
        expect(build(:message, email: "john.doe@company.com")).to be_valid
        expect(build(:message, email: "user123@gmail.com")).to be_valid
      end
    end

    describe "phone validation" do
      it "rejects phone numbers with repetitive patterns" do
        expect(build(:message, phone: "1111111111")).to_not be_valid
        expect(build(:message, phone: "555-555-5555")).to_not be_valid
      end

      it "rejects obviously fake phone numbers" do
        expect(build(:message, phone: "0000000000")).to_not be_valid
        expect(build(:message, phone: "1234567890")).to_not be_valid
      end

      it "rejects invalid length phone numbers" do
        expect(build(:message, phone: "123456789")).to_not be_valid  # too short
        expect(build(:message, phone: "123456789012")).to_not be_valid  # too long
      end

      it "accepts legitimate phone numbers" do
        expect(build(:message, phone: "555-123-4567")).to be_valid
        expect(build(:message, phone: "15551234567")).to be_valid
        expect(build(:message, phone: "")).to be_valid  # blank is okay
      end
    end

    describe "content validation" do
      it "rejects content with excessive links" do
        spammy_content = "Check out www.spam1.com and www.spam2.com and www.spam3.com"
        expect(build(:message, content: spammy_content)).to_not be_valid
      end

      it "allows content with reasonable number of links" do
        good_content = "Please visit our website at www.example.com for more info"
        expect(build(:message, content: good_content)).to be_valid
      end

      it "rejects overly long content" do
        long_content = "a" * 2001
        expect(build(:message, content: long_content)).to_not be_valid
      end

      it "rejects content with repetitive patterns" do
        expect(build(:message, content: "spam spam spam spam")).to_not be_valid
        expect(build(:message, content: "aaaaaaaaaaa")).to_not be_valid
      end

      it "rejects content with excessive capitalization" do
        expect(build(:message, content: "THIS IS ALL CAPS MESSAGE")).to_not be_valid
      end

      it "rejects content with spam phrases" do
        expect(build(:message, content: "Make money fast with this offer!")).to_not be_valid
        expect(build(:message, content: "Click here to buy now!")).to_not be_valid
        expect(build(:message, content: "Work from home guaranteed income")).to_not be_valid
      end

      it "rejects content with excessive special characters" do
        expect(build(:message, content: "!@#$%^&*()_+{}|:<>?")).to_not be_valid
      end

      it "accepts legitimate content" do
        expect(build(:message, content: "I would like to add my nonprofit organization to your platform.")).to be_valid
      end
    end
  end
end
