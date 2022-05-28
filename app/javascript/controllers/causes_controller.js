import { Controller } from "@hotwired/stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static targets = [ "list" ]

  listTargetConnected(target) {
    new Tagify(
      target, { whitelist:  ["Advocacy",
      "Animals",
      "Arts & Culture",
      "Children & Family Services",
      "Clothing & Living Essentials",
      "Community & Economic Development",
      "Disability Services",
      "Disaster Relief & Preparedness",
      "Drug & Alcohol Treatment",
      "Education",
      "Emergency & Safety",
      "Employment",
      "Environment",
      "Faith-Based",
      "Health",
      "Housing & Homelessness",
      "Human & Social Services",
      "Hunger & Food Security",
      "Immigrant & Refugee",
      "Inmate & Formerly Incarcerated",
      "International",
      "Justice & Legal Services",
      "LGBTQ+",
      "Media & Broadcasting",
      "Mental Health",
      "Philanthropy",
      "Race & Ethnicity",
      "Research & Public Policy",
      "Science & Technology",
      "Seniors",
      "Social Sciences",
      "Sports & Recreation",
      "Transportation",
      "Veteran & Military",
      "Youth Development"],
      maxTags: 10,
      dropdown: {
        maxItems: 35,           // <- mixumum allowed rendered suggestions
        classname: "tags-look", // <- custom classname for this dropdown, so it could be targeted
        enabled: 0,             // <- show suggestions on focus
        closeOnSelect: false }    // <- do not hide the suggestions dropdown once an item has been selected
      });
  }
}
