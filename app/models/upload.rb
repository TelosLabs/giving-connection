# frozen_string_literal: true

class Upload 

  def import(spreadsheet)
    file_path = File.open(File.join(Rails.root, 'db', 'uploads'))
    csv_file_paths = spreadsheet_to_csv(spreadsheet, file_path)
    create_models(csv_file_paths)
  end


  def spreadsheet_to_csv(spreadsheet, file_path)
    data_spreadsheet = Roo::Spreadsheet.open(spreadsheet)

    files_name = ["orgs.csv", "tags.csv", "beneficiaries.csv", "locations.csv",
                  "location_services.csv", "location_office_hours.csv"]

    files_name.each_with_index do |file_name, sheet|
      data_spreadsheet.default_sheet = data_spreadsheet.sheets[sheet]
      data_spreadsheet.to_csv("#{file_path.path}/#{file_name}")
    end

    paths = 
        { orgs_csv_file: "#{file_path.path}/orgs.csv", 
          tags_csv_file: "#{file_path.path}/tags.csv",
          beneficiaries_csv_file: "#{file_path.path}/beneficiaries.csv",
          locations_csv_file: "#{file_path.path}/locations.csv",
          location_services_csv_file: "#{file_path.path}/location_services.csv",
          location_office_hours_csv_file: "#{file_path.path}/location_office_hours.csv" 
        } 
  end

  def create_models(csv_file_paths)
    CSV.foreach(csv_file_paths[:orgs_csv_file], headers: :first_row) do |org_row|
      new_organization_data =  { name: org_row['name'], ein_number: org_row['ein_number'], irs_ntee_code: org_row['irs_ntee_code'],
          mission_statement_en: org_row['mission_statement_en'], vision_statement_en: org_row['vision_statement_en'],
          tagline_en: org_row['tagline_en'], description_en: org_row['description_en'],
          mission_statement_es: org_row['mission_statement_es'], vision_statement_es: org_row['vision_statement_es'],
          tagline_es: org_row['tagline_es'], description_es: org_row['description_es'], website: org_row['website'],
          scope_of_work: org_row['scope_of_work'], creator: AdminUser.first }

      new_organization = Organization.new(new_organization_data)

      if new_organization.save
        social_media_data = { facebook: org_row['facebook'], instagram: org_row['instagram'], twitter: org_row['twitter'],
            linkedin: org_row['linkedin'], youtube: org_row['youtube'], blog: org_row['blog'], organization: new_organization }

        new_social_media = SocialMedia.create(social_media_data)
        
        CSV.foreach(csv_file_paths[:tags_csv_file], headers: :first_row) do |tag_row|
          if tag_row['organization_id'] == org_row['id']
            new_tag = Tag.create(name: tag_row['name'], organization: new_organization)
          end
        end
      

      
        CSV.foreach(csv_file_paths[:beneficiaries_csv_file], headers: :first_row) do |beneficiary_row|
          if beneficiary_row['organization_id'] == org_row['id']
            beneficiary_subcategory = BeneficiarySubcategory.find_by_name(beneficiary_row['name'])
            new_organization_beneficiaries = 
              OrganizationBeneficiary.create(beneficiary_subcategory: beneficiary_subcategory, organization: new_organization)
          end
        end

        CSV.foreach(csv_file_paths[:locations_csv_file], headers: :first_row) do |location_row|
          if location_row['organization_id'] == org_row['id']
            new_location = Location.create(address: location_row['address'], website: location_row['website'],
                                        main: location_row['main'] == 'yes', physical: location_row['physical'] == 'yes',
                                        appointment_only: location_row['appointment_only'] == 'yes',
                                        offer_services: location_row['offer_services'] == 'yes', organization: new_organization, 
                                        latitude: location_row['latitude'].to_f, longitude: location_row['longitude'].to_f)
            
            CSV.foreach(csv_file_paths[:location_services_csv_file], headers: :first_row) do |location_service_row|
              if location_row['id'] == location_service_row['location_id']
                service = Service.find_by_name(location_service_row['name'])
                new_location_service = LocationService.create(service: service, location: new_location)
              end
            end
          end
        end
      end
    end
  end

end
