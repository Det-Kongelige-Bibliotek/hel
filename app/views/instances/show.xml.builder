xml.mods({'xmlns' => 'http://www.loc.gov/mods/v3'}) do 
  @w = @instance.work
  @w.titles.each do |tit|
    xml.titleInfo do |title|
      xml.title(tit.value)
    end
  end
end
