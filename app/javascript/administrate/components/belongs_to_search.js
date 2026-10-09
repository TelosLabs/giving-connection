import $ from 'jquery'
import "selectize/dist/js/standalone/selectize"

// Powers BelongsToSearchField: the <select> only has the current value (if
// any) preloaded, so search-as-you-type hits the association's own index
// action in JSON format (Administrate's existing, already-tested search --
// see app/views/administrate/application/index.json.jbuilder) instead of
// ever sending every row to the browser.
$(document).on("turbo:load", function() {
  $('.field-unit--belongs-to-search-field select').each(function initializeSelectize() {
    var $element = $(this)

    $element.selectize({
      valueField: 'id',
      labelField: 'dashboard_display_name',
      searchField: 'dashboard_display_name',
      create: false,
      preload: false,
      load: function(query, callback) {
        if (!query.length) return callback()
        $.ajax({
          url: $element.data('url'),
          data: {search: query},
          type: 'GET',
          error: function() { callback() },
          success: function(res) { callback(res.resources) }
        })
      }
    })
  })
})
