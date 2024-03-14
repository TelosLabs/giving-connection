class SavedSearchAlertMailerPreview < ActionMailer::Preview
  def send_alert
    alert = Alert.new(
      id: 2,
      user_id: 2,
      distance: '',
      city: 'Nashville',
      state: 'TN',
      services: nil,
      open_now: nil,
      open_weekends: false,
      keyword: '',
      beneficiary_groups: nil,
      frequency: 'daily',
      search_results: ['15', '20', '30', '39', '6']
    )

    SavedSearchAlertMailer.send_alert(alert)
  end
end
