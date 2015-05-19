class InstanceSerializer 

  def self.build (instance)
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.mods({ 'xmlns' => 'http://www.loc.gov/mods/v3', 
                 'xmlns:xlink' => 'http://www.w3.org/1999/xlink', 
                 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",  
                 'xsi:schemaLocation' => "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd",
                 'version' => "3.5"}
               ) do 
        @w = instance.work
        @w.titles.each do |tit|
          xml.titleInfo do
            xml.title(tit.value)
            if tit.subtitle.present?
              xml.subTitle(tit.subtitle)
            end
          end
        end
        if @w.language.present? then
          xml.language do
            xml.languageTerm( @w.language.split("/").last, 
                              "valueURI" => @w.language,
                              "type" => "code", 
                              "authority" => "iso639-2b")
          end
        end
        (@w.relators + instance.relators).each do |rel|
          
          role_uri = rel.role
          role  = rel.short_role
          agent = rel.agent 
          #    "production", "publication", "distribution", "manufacture" 
          if role == "pbl" then
            render_origin_info(@w,agent,instance,role_uri,role,'publication')
          else
            render_agent(agent,rel,role,role_uri)
          end
        end 
        if instance.uri then 
          xml.identifier(instance.uri,"type" => "uri")
        end

        if instance.collection.present? then
          xml.relatedItem("type" => "host") do
            xml.titleInfo do
              xml.title(instance.collection)
            end
            xml.typeOfResource("collection" => "yes")
          end
        end

        @w.related_works.each do |pre|
          xml.relatedItem("type" => "preceding") do
            pre.titles.each do |tit|
              xml.titleInfo do
                xml.title(tit.value)
                if tit.subtitle.present?
                  xml.subTitle(tit.subtitle)
                end
              end
            end
            xml.identifier do
              xml.identifier(pre.uri,"type" => "uri")
            end
          end
        end

        @w.preceding_works.each do |pre|
          xml.relatedItem("type" => "preceding") do
            xml.identifier do
              xml.identifier(pre.uri,"type" => "uri")
            end
          end
        end

        @w.succeeding_works.each do |succ|
          xml.relatedItem("type" => "succeeding") do
            xml.identifier do
              xml.identifier(succ.uri,"type" => "uri")
            end
          end
        end

      end

    end
    builder.to_xml
  end

  def self.render_agent (agent,rel,role,role_uri)

    builder = Nokogiri::XML::Builder.new do |xml|
      if agent.class == Authority::Person then
        xml.name("type" => "personal", "valueURI" => agent.uri, ) do
          if agent.family_name.present? then
            xml.namePart(agent.family_name,"type" => "family")
          end
          if agent.family_name.present? then
            xml.namePart(agent.given_name,"type" => "given")
          end
          if agent.birth_date.present? || agent.death_date.present?  then
            date = agent.display_date
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
            date = agent.display_date
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
    builder.to_xml
  end

  def self.render_origin_info(work,agent,instance,role_uri,role,event)
    builder = Nokogiri::XML::Builder.new do |xml|
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
    end
    builder.to_xml
  end

end
