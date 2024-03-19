# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string
#
require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    subject { create(:user) }

    it { is_expected.to have_many(:organizations) }
    it { is_expected.to have_many(:alerts) }
    it { is_expected.to have_many(:fav_locs).class_name("FavoriteLocation") }
    it { is_expected.to have_many(:favorited_locations).through(:fav_locs).source(:location) }
    it { is_expected.to have_many(:organization_admin) }
    it { is_expected.to have_many(:administrated_organizations).through(:organization_admin).source(:organization) }
  end
end
