import { Controller } from "stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static targets = [ "output" ]
  
  connect() {
    // let whitelist = this.outputTarget.dataset.whitelist.trim();
    console.log('connect');
    new Tagify(
      this.outputTarget);
  }
}