FactoryBot.define do
  factory :message do
    name { 'Kevin' }            
    email { 'kevinsito@email.com' }
    phone { '12345678910' }
    subject { 'Lorem' }
    organization_name { "Kev's Org" }
    organization_website { 'kevsorg.com' }
    organization_ein { '123456' }
    content { 'Lorem ipsum dolor' }
  end
end
