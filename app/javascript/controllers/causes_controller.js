import { Controller } from "@hotwired/stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static targets = [ "list" ]
  static values = {
    options: Array
  }

  listTargetConnected(target) {
    new Tagify(
      target, { whitelist: this.optionsValue,
      maxTags: 10,
      dropdown: {
        maxItems: 35,           // <- mixumum allowed rendered suggestions
        classname: "tags-look", // <- custom classname for this dropdown, so it could be targeted
        enabled: 0,             // <- show suggestions on focus
        closeOnSelect: false }    // <- do not hide the suggestions dropdown once an item has been selected
      });
  }
}
