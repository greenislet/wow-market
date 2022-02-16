import { Controller } from "@hotwired/stimulus"

export default class Dropdown extends Controller {

  static targets = ["submit"];
  static locales = [
    "en",
    "es",
    "pt",
    "fr",
    "ru",
    "it",
    "ko",
    "zh",
  ];

  static idx = 0;

  selectClick(event) {
    this.submitTarget.textContent = event.path[0].textContent;
    this.submitTarget.setAttribute("selected_idx", event.path[0].attributes["idx"].value);

    var lang = Dropdown.locales[parseInt(this.submitTarget.attributes["selected_idx"].value)];
    window.location = window.location.protocol + "//" + window.location.host + window.location.pathname + `?lang=${lang}`;
  }

}
