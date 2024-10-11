class AlertService < ApplicationRecord
  belongs_to :alert
  belongs_to :service
end
