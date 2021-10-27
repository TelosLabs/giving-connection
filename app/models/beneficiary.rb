class Beneficiary < ApplicationRecord
	has_many :beneficiary_subcategories, dependent: :destroy
end
