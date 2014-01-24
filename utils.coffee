exports.portal_config = (portal_name) ->
    require "./portals/#{portal_name}.coffee"
