# Tell Rails it knows how to handle these types
Mime::Type.register 'application/rdf+xml' , :rdf , [], %w(rdf)
Mime::Type.register 'application/xml', :mods, [], %w(mods)
# Tell Rails to call the .to_rdf method when asked to render rdf
ActionController::Renderers.add :rdf do |obj, _options|
  obj.to_rdf
end
ActionController::Renderers.add :mods do |obj, _options|
  obj.to_mods
end
