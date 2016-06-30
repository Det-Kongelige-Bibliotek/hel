require 'spec_helper'

# Since most Instance functionality is defined
# in Bibframe::Instance, most tests take place
# in the corresponding spec. Only test logic that
# is not encapsulated in Bibframe::Instance here,
# e.g. validations, relations etc.
describe XML::InstanceSerializer do
  include_context 'shared'

  describe 'Simple instance' do
    before :each do
      agent = Authority::Person.create('given_name'=> 'Fornavn',
                                       'family_name' => 'Efternavn',
                                       'birth_date' => '1932' ,
                                       'death_date' => '2009')
      @org =  Authority::Organization.new(_name: 'Gyldendalske boghandel, Nordisk forlag',
                                          founding_date: '1770')
      @org.alternate_names.push 'Gyldendal'
      @org.save
      @instance = Instance.new(valid_trykforlaeg)
      @work = Work.new(work_params)
      @work.add_author(agent)
      @instance.set_work=@work
      @instance.add_publisher(@org)
      @work.instances += [@instance]

      @work.save!

      @instance.languages = ['http://id.loc.gov/vocabulary/languages/tlh']
      @instance.isbn13 = '978-0-123456-47-2'
      @instance.isbn10 = '1234567890'
      @instance.mode_of_issuance = 'Monographic'
      @instance.extent = 'The void'
      @instance.note = 'Noting'
      @instance.title_statement = 'The proclamation of the title'
      @instance.dimensions = '7 + 1'
      @instance.contents_note = 'Equivalent to formatted contents note, subfield a of MARC field 505.'
      @instance.system_number = 'Control number of a system other than LCCN or NBAN, which Identifies a resource description.'
      @instance.copyright_date = 'unknown/unknown'
      @instance.collection = ["Danske Samlinger", "Billedsamlingen og Bladtegnersamlingen"]
      @instance.save!

      @work.language = 'http://id.loc.gov/vocabulary/languages/jbo'
      @work.origin_date = 'unknown/unknown'
      @work.save!
    end

    it 'should create xml metadata' do
      xml = XML::InstanceSerializer.to_mods(@instance)
      xsd = Nokogiri::XML::Schema(open('http://www.loc.gov/standards/mods/v3/mods-3-6.xsd').read)
      errors = xsd.validate(Nokogiri::XML.parse(xml) { |config| config.strict })
      expect(errors).to be_empty
    end
  end

end
