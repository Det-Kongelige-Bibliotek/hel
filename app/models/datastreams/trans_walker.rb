module Datastreams
  
  module TransWalker 

    def from_mods(mods)
      @mods = mods

      if(self.is_a? Instance) then
        self.to_instance(@mods)
      elsif(self.is_a? Work) then
        self.to_work(@mods)
      else
        fail "Neither Work nor Instance"
      end
    end

    def to_work(mods)

      s = mods.nonSort.first.present? ?  mods.nonSort.first + " " : ""
      t = s + mods.title.first
      tit = {
        value: t,
        subtitle: mods.subTitle.first,
        lang: ''
      }
      
      self.add_title(tit)

      mods.person.nodeset.each do |p|
        ns = p.namespace.href
        family = p.xpath('car:namePart[@type="family"]','car'=>ns).text
        given  = p.xpath('car:namePart[@type="given"]','car'=>ns).text
        date   = p.xpath('car:namePart[@type="date"]','car'=>ns).text

        if(!family.blank? or !given.blank?) then
          nhash = {'scheme' => 'KB', 'family' => family, 'given' => given, 'date' => date}
        else
          full  = p.xpath('car:namePart','car'=>ns).text
          nhash = {'scheme' => 'KB', 'full' => full, 'date' => date}
        end
        name={authorized_personal_name: nhash }
        mads=Authority::Person.create(name)
        self.add_author(mads)
      end

      self.origin_date  = mods.dateIssued.first

      place = Authority::Place.create(_name: mods.originPlace.first)
      self.origin_place = place
      self
    end

    def to_instance(mods)

      self.note=mods.note

      # self.note
      # self.identifier 
      # self.Identifier

      # self.language
      # self.mode_of_issuance(path: 'modeOfIssuance')
      # self.title_statement(path: 'titleStatement', index_as: :stored_searchable)
    
      self.extent=mods.physicalExtent.first 

      # self.dimensions
      # self.contents_note(path: 'contentsNote')
      # self.isbn13(proxy: [:isbn_13, :Identifier, :label])

      self.isbn13=mods.isbn.first

      #
      # self.publication 
      # self.Provider 
      # self.copyrightDate
      # self.providerDate

      # publication There is hardly any way we can distinguish between a
      # copyright date and a date of issuance, or is there?

      # self.copyright_date(proxy: [:publication, :Provider, :copyrightDate])

      # Don't know what happens if these are repeated.

      # this should use the relator style instead
      pub = Authority::Organization.create(_name: mods.publisher.first)
      self.add_publisher(pub)


    end

    
  end
end
