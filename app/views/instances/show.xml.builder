xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.mods({'xmlns' => 'http://www.loc.gov/mods/v3'}) do 
  @w = @instance.work
  @w.titles.each do |tit|
    xml.titleInfo do |title|
      xml.title(tit.value)
      if tit.subtitle.present? do
          xml.subTitle(tit.subtitle)
        end
      end
    end
  end
  @w.relators.each do |rel|
    rel.each do |agent|
      xml.name("got relator")
      xml.name("got relator")
    end
  end
end
