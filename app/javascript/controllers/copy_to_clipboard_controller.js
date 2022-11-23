import { Controller } from "@hotwired/stimulus"


export default class extends Controller {
  static targets = [ "button" ]

  copyContent(event){
    let text_to_copy = event.params.content

    if (!navigator.clipboard){
      let dummy = document.createElement('input')
      document.body.appendChild(dummy)
      dummy.value = text_to_copy
      dummy.select()
      document.execCommand('copy')
      document.body.removeChild(dummy)
    } else{
      navigator.clipboard.writeText(text_to_copy).then(
        function(){
          alert("Copied to clipboard!")
        })
    }
  }
}
