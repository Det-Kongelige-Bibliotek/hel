require 'spec_helper'

describe ConversionService do

  before do
    @service = AlephService.new
    # set = @service.find_set("sys=001401044") hak hak
    set = @service.find_set("sys=001541111") # tove
    # set = @service.find_set("sys=001364118") # hak hak
    # set = @service.find_set("isbn=9788711396322") 
    # set = @service.find_set("isbn=9780691129785")
    rec = @service.get_record(set[:set_num],set[:num_entries])
    puts rec
    @converter = ConversionService.new(rec)
  end

 describe 'to_mods' do
    before :all do 
      @instance = Instance.create
    end
    it 'is wellformed XML' do
      xsd = Nokogiri::XML::Schema(open('http://www.loc.gov/standards/mods/v3/mods-3-5.xsd').read)
      doc = @converter.to_mods("")
      #puts @converter.to_marc21("")
      puts doc.to_xml
      errors = xsd.validate(doc) { |config| config.strict }
      expect(errors).to eql []
    end
  end
end
