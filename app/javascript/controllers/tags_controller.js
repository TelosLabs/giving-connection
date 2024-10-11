import { Controller } from "@hotwired/stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static targets = ["output"]

  connect() {
    new Tagify(this.outputTarget); // internally changes `value`
    this.outputTarget.defaultValue = this.outputTarget.value // keeps input consistent
  }
}
