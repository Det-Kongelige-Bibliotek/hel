xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.mods({ 'xmlns' => 'http://www.loc.gov/mods/v3', 
           'xmlns:xlink' => 'http://www.w3.org/1999/xlink', 
           'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",  
           'xsi:schemaLocation' => "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd",
           'version' => "3.5"}
         ) do 
  @w = @instance.work
  @w.titles.each do |tit|
    xml.titleInfo do |title|
      xml.title(tit.value)
      if tit.subtitle.present?
          xml.subTitle(tit.subtitle + @w.id)
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
  (@w.relators + @instance.relators).each do |rel|
    role_uri = rel.role
    role = role_uri.split("/").last
    agent = rel.agent 
#    "production", "publication", "distribution", "manufacture" 
    if role == "pbl" then
      xml << render(
                    :partial => 'instances/mods_origin', 
                    :locals => 
                    { :agent => agent, 
                      :work => @w, 
                      :instance => @instance,
                      :role_uri => role_uri,
                      :role => role,
                      :event => 'publication' }
                    )
    else
      xml << render(:partial => 'instances/mods_name', 
                    :locals => { :agent => agent, :rel =>rel } )
    end
  end
end

