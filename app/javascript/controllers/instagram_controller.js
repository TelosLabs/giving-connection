import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    let userFeed = new Instafeed({
      get: 'user',
      target: "instagram-feed-container",
        resolution: 'low_resolution',
      template: `<div>
                  <a href="{{link}}" target="_blank" class="w-10">
                    <img title="{{caption}}" src="{{image}}"/>
                  </a>
                </div>`,
      accessToken: 'IGQVJVSWFGR0JfbTd5NVlJbnFnbFctR0MyVGZAhcl9tTVdwYnd1TGZAXS0xnRHh2Qy1PNmdGSHRMS01BemY0RmIzeldvWktzYWNvNEVwcERaMUdPcHQ0Y0ZASdmRtRHBiM1RUSzFCSThQaDYtblk0c244OAZDZD'
    })
    console.log(userFeed)
    userFeed.run()
  }
}
