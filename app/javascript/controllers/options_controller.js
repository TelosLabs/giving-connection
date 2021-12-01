import { Controller } from "@hotwired/stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static target = [ "list" ]


  listTargetConnected(target) {
    new Tagify(
      target);
  }
}
