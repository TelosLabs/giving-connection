import { Controller } from "@hotwired/stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static target = [ "list" ]

  listTargetConnected(target) {
    new Tagify(
      target, { whitelist: ["Adults",
      "Children & Youth",
      "Individuals Under 21",
      "Seniors",
      "Indigenous Peoples",
      "Multiracial People",
      "People of African Descent",
      "People of Asian Descent",
      "People of European Descent",
      "People of Latin American Descent",
      "People of Middle Eastern Descent",
      "People of all Racial Minority Groups",
      "Caregivers",
      "Families",
      "Non-Adults",
      "Parents",
      "Widows & Widowers",
      "Heterosexuals",
      "Intersex People",
      "LGBTQ+ People",
      "Men & Boys",
      "Women & Girls",
      "People with Developmental Disabilities",
      "People with Diseases & Illnesses",
      "People with Mental Health Issues",
      "People with Physical Disabilities",
      "People with Substance Abuse Issues",
      "Pregnant People",
      "Baha'is",
      "Buddhists",
      "Christians",
      "Confucists",
      "Hindus",
      "Interfaith Groups",
      "Jewish People",
      "Muslims",
      "Secular Groups",
      "Shintos",
      "Sikhs",
      "Tribal & Indigenous Religious Groups",
      "At-Risk Youth",
      "Economically Disadvantaged People",
      "Formerly Incarcerated People",
      "Immigrants & Migrants",
      "Incarcerated People",
      "Nomadic People",
      "People Struggling with Homelessness",
      "Victims & Oppressed People",
      "Academics",
      "Activists",
      "Artists & Performers",
      "Domestic Workers",
      "Emergency Responders",
      "Farmers",
      "Military Personnel",
      "Retired People",
      "Self Employed People",
      "Sex Workers",
      "Unemployed People",
      "Veterans"],
      maxTags: 10,
      dropdown: {
        maxItems: 60,           // <- mixumum allowed rendered suggestions
        classname: "tags-look", // <- custom classname for this dropdown, so it could be targeted
        enabled: 0,             // <- show suggestions on focus
        closeOnSelect: false }    // <- do not hide the suggestions dropdown once an item has been selected
      });
  }
}


