xml.originInfo('eventType' => event ) do
  if work.origin_place.present? then
    place=work.origin_place
    xml.place do 
      xml.placeTerm(place.display_value, "valueURI" => place.same_as)
    end
  end
  xml.publisher(agent.display_value) #, "xlink:href" => agent.same_as)
  xml.dateCreated(work.origin_date)
end
