# Index (JSON)
#
# Backs BelongsToSearchField's Selectize search box: any dashboard's index
# action, requested as JSON, returns matching resources for the existing
# `?search=` query (Administrate::Search -- the same search used by the
# index page's search bar), capped by the existing pagination.
#
# Local variables:
# - `resources`: the (already searched + paginated) ActiveRecord::Relation.
#
# `@dashboard` is set by the controller's `index` action (it memoizes into
# that ivar), not passed as a local -- same as Administrate's own ivar-based
# view conventions elsewhere.

json.resources resources do |resource|
  json.id resource.id
  json.dashboard_display_name @dashboard.display_resource(resource)
end
