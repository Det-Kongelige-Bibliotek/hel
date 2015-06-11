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
        family = p.xpath('mods:namePart[@type="family"]','mods'=>ns).text.delete("\n").delete("\t")
        given  = p.xpath('mods:namePart[@type="given"]','mods'=>ns).text.delete("\n").delete("\t")
        full  = p.xpath('mods:namePart','mods'=>ns).text.delete("\n").delete("\t")
        date   = p.xpath('mods:namePart[@type="date"]','mods'=>ns).text

        if family.present? || given.present?
          author = Authority::Person.new(given_name: given, family_name: family)
        else
          author = Authority::Person.new(_name: full)
        end
        self.add_author(author)
      end

      self.origin_date  = mods.dateIssued.first

      place = Authority::Place.find_or_create(_name: mods.originPlace.first)
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

      pub = Authority::Organization.find_or_create(_name: mods.publisher.first)
      self.add_publisher(pub)


    end

    
  end
end
