import { Controller } from "@hotwired/stimulus"

export default class RealmsTable extends Controller {

  static ids = []

  connect() {
    $('#realms-table').DataTable( {
      processing: true,
      serverSide: true,
      ajax: "/data/realms",
    });

    $('#realms-table').on('xhr.dt', function ( e, settings, json, xhr ) {
      RealmsTable.ids = json.ids
    });

    $('#realms-table').on( 'draw.dt', function () {
      $('table > tbody  > tr').each(function(index, tr) {
        tr.setAttribute("value", RealmsTable.ids[index])
        tr.setAttribute("data-action", "click->realmsTable#clickRow")
      });
    });

    $('#tableContainer').css({"visibility": "visible"});
  }

  clickRow(e) {
    var realmId = e.srcElement.parentElement.attributes["value"].value;
    window.location = `/realms/${realmId}`;
  }

}
