class AlertBeneficiary < ApplicationRecord
  belongs_to :alert
  belongs_to :beneficiary_subcategory
end
