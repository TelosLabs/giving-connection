import { Controller } from "@hotwired/stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static target = [ "options" ]

  optionsTargetConnected(target) {
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


