class AlertCause < ApplicationRecord
  belongs_to :alert
  belongs_to :cause
end