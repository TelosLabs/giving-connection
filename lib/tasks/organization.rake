namespace :organization do
  desc 'assigns admins to organizations'
  task assign_admin: :environment do
    org_admin_arr = [
      {
        org_name: 'A Step Ahead of Middle Tennessee',
        admin_email: 'kristin@astepaheadmiddletn.org'
      },
      {
        org_name: 'Pawster',
        admin_email: 'gabe@pawsternashville.org'
      },
      {
        org_name: 'ABC Sports Foundation',
        admin_email: 'info@abcsports.org'
      },
      {
        org_name: 'The Forge Nashville',
        admin_email: 'erin@theforgenashville.org'
      },
      {
        org_name: 'Exile International',
        admin_email: 'Taylor@exileinternational.org'
      },
      {
        org_name: 'Faith Family Medical Center',
        admin_email: 'emaggart@faithmedical.org'
      },
      {
        org_name: 'Eakin School Parent Teacher Organization',
        admin_email: 'eakinpto@gmail.com'
      }
    ]

    org_admin_arr.each do |org_admin|
      organization = Organization.find_by(name: org_admin[:org_name])
      admin = User.find_by(email: org_admin[:admin_email])
      if organization.blank? || admin.blank?
        Rails.logger.info 'An error has ocurred'
        Rails.logger.info "Organization: #{org_admin[:org_name]} was not found" if admin.blank?
        Rails.logger.info "User: #{org_admin[:admin_email]} was not found" if organization.blank?
        next
      end
      OrganizationAdmin.create!(
        organization: organization,
        user: admin,
        role: 'admin'
      )
      Rails.logger.info "User #{admin.email}-#{admin.id} succesfully assigned to Organization #{organization.name}-#{organization.id}"
    rescue => ex
      Rails.logger.info "#{ex} for Organization: #{org_admin[:org_name]}"
    end
  end
end
