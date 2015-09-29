require 'spec_helper'

describe 'content' do

  it 'should validate the content of a file' do
    v = Validator::Xml.new
    schema = Rails.root.join('spec', 'fixtures', 'tei_all.rng')
    v.set_schema(schema)
    doc = 'holb06valid.xml'
    f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures',doc))
    expect(v.is_valid_xml_content(f.read).blank?).to be true
  end

  it 'should complain about invalid xml content' do
    v = Validator::Xml.new
    schema = Rails.root.join('spec', 'fixtures', 'tei_all.rng')
    v.set_schema(schema)
    doc = 'holb06notwellformed.xml'
    f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures',doc))
    expect(v.is_valid_xml_content(f.read).blank?).to be false
  end

  it 'should not complain about valid files' do
    c = ContentFile.new
    v = Validator::Xml.new
    schema = Rails.root.join('spec', 'fixtures', 'tei_all.rng')
    v.set_schema(schema)
    doc = 'holb06valid.xml'
    f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures',doc))
    c.add_file(f)
    c.save
    puts "******\n" + doc
    isOK = v.validate c
    msg = c.errors[:base].join(" ")
    puts msg
    expect(isOK).to be true
  end

  it 'should allow to test the validity of files' do
    c = ContentFile.new
    v = Validator::Xml.new
    schema = Rails.root.join('spec', 'fixtures', 'tei_all.rng')
    v.set_schema(schema)
    doc = 'holb06invalid.xml'
    f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures',doc))
    c.add_file(f)
    c.save
    puts "******\n" + doc
    isOK = v.validate c
    msg = c.errors[:base].join(" ")
    puts msg
    expect(isOK).to be false
  end

  it 'should capture invalid files using XSD as well' do
    c = ContentFile.new
    v = Validator::Xml.new
    schema = Rails.root.join('spec', 'fixtures', 'mods-3-5.xsd')
    v.set_schema(schema)
    doc = 'mods_with_subject_person_and_invalid_subtitle.xml'
    p   = Pathname.new(Rails.root).join('spec', 'fixtures', doc)
    f = File.new(p)
    c.add_file(f)
    c.save
    puts "******\n" + doc
    isOK = v.validate c
    msg = c.errors[:base].join(" ")
    puts msg
    expect(isOK).to be false
  end

  it 'should also capture files that are not wellformed' do
    c = ContentFile.new
    v = Validator::Xml.new
    doc = 'holb06notwellformed.xml'
    f = File.new(Pathname.new(Rails.root).join('spec', 'fixtures',doc))
    c.add_file(f)
    c.save
    puts "******\n" + doc
    isOK = v.validate c
    msg = c.errors[:base].join(" ")
    puts msg
    expect(isOK).to be false
  end

end
