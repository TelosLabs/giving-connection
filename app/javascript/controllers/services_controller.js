import { Controller } from "@hotwired/stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static target = [ "options" ]

  optionsTargetConnected(target) {
    console.log("Jewish")
    new Tagify(
      target, { whitelist: ["Adults", "Children and Youth", "Indigenous peoples", "Multiracial people", "People of African descent", "People of Asian descent", "People of European descent", "People of Latin American descent", "People of Middle Eastern descent", "Caregivers", "Families", "Non-adults", "Parents", "Widows and widowers", "Heterosexuals", "Intersex People", "LGBTQ People", "Men and Boys", "Women and girls", "People with disabilities", "People with diseases and illness", "Pregnant people", "People with substance abuse issues", "Baha'is", "Buddhists", "Christians", "Confucists", "Hindus", "Interfaith groups", "Jewish People", "Muslims", "Secular groups", "Shintos", "Sikhs", "Tribal and indigenous religivous groups", "At-risk youth", "Economically disavantaged people", "Immigrants and migrants", "Incarcerated people", "Nomadic People", "Victims and oppressed people (victims of conflict and war, victims of crime and abuse, victims of disaster)", "Academics", "Activists", "Artists and performers", "Domestic workers", "Emergency responders", "Farmers", "Military personnel", "Retired people", "Self employed people", "Sex workers", "Unemployed people", "Veterans"],
      maxTags: 10,
      dropdown: {
        maxItems: 20,           // <- mixumum allowed rendered suggestions
        classname: "tags-look", // <- custom classname for this dropdown, so it could be targeted
        enabled: 0,             // <- show suggestions on focus
        closeOnSelect: false }    // <- do not hide the suggestions dropdown once an item has been selected
      });
  }
}


// div class="hidden col-span-3 md:flex" 
// div class="col-span-12 lg:col-span-5 md:col-span-7"
//   fieldset class='mt-4'
//     p class="text-sm font-medium leading-4 text-gray-2"
//       | Services offered on this location
//     div class='flex items-center gap-12 mt-3' data-controller="services"
//       - values = @location.location_services.map { |location_service| location_service.service.name }.join(', ')
//       = f.label :beneficiary_subcategories, "What target populations (beneficiaries) best describe who you serve?", class: "block text-sm text-gray-3 font-medium"
//       = f.text_field :beneficiary_subcategories, { data: { 'services-target': 'options' }, placeholder:'Write some', value: values, class: "block h-46px bg-white mt-1 h-full w-full py-0 px-4 rounded-6px border-gray-5 text-base text-gray-3 focus:ring-blue-medium focus:border-blue-medium" } 