xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.mods({'xmlns' => 'http://www.loc.gov/mods/v3', 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",  'xsi:schemaLocation' => "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd",'version' => "3.5"}) do 
  @w = @instance.work
  @w.titles.each do |tit|
    xml.titleInfo do |title|
      xml.title(tit.value)
      if tit.subtitle.present?
          xml.subTitle(tit.subtitle)
      end
    end
  end
  (@w.relators + @instance.relators).each do |rel|
    role_uri = rel.role
    role = role_uri.split("/").last
    agent = rel.agent 
    if agent.class == Authority::Person then
      xml.name("type" => "personal", "valueURI" => agent.uri, ) do
        if agent.family_name.present? then
          xml.namePart(agent.family_name,"type" => "family")
        end
        if agent.family_name.present? then
          xml.namePart(agent.given_name,"type" => "given")
        end
        if agent.birth_date.present? || agent.death_date.present?  then
          date = ""
          if agent.birth_date.present? then
            date += agent.birth_date + "-"
          end
          if agent.death_date.present?  then
            if agent.birth_date.present? then
              date += agent.death_date
            else
              date = "-" + agent.death_date
            end
          end
          xml.namePart(date, "type" => "date")
        end
        xml.role do
          xml.roleTerm(role, "authorityURI" => role_uri, "type"=>"code")
        end
      end
    elsif agent.class == Authority::Organization then
      xml.name("authorityURI" => agent.uri, "type" => "corporate") do
        xml.namePart(agent.display_value)
        if agent.founding_date.present? || agent.dissolution_date.present? then
          date = ""
          if agent.founding_date.present? then
            date += agent.founding_date + "-"
          end
          if agent.dissolution_date.present?  then
            if agent.founding_date.present? then
              date += agent.dissolution_date
            else
              date = "-" + agent.dissolution_date
            end
          end
          xml.namePart(date, "type" => "date")
        end
        xml.role do
          xml.roleTerm(role, "authorityURI" => role_uri, "type"=>"code")
        end
      end
    else
      xml.name("authorityURI" => agent.uri, "type" => "undef") do
        xml.namePart(agent.display_value )
        xml.role do
          xml.roleTerm(role, "authorityURI" => role_uri, "type"=>"code")
        end
      end
    end
  end
end

