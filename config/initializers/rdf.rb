# Tell Rails to call the .to_rdf method when asked to render rdf
ActionController::Renderers.add :rdf do |obj, _options|
  obj.to_rdf
end
