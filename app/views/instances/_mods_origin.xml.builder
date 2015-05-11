xml.originInfo do
  if work.origin_place.present? then
    place=work.origin_place
    xml.place(place.display_value)
  end
  xml.publisher(agent.display_value, "authorityURI" => agent.uri)
  xml.dateCreated(work.origin_date)
end
