require 'spec_helper'

describe DisseminationProfiles::Adl do
  include_context 'shared'

#  let(:sample_work) { Work.create(work_params)}

  # Given an ADL tei file
  # When I call transform on DisseminationProfiles::ADL
  # It will produce the correct Solr output
  it 'should produce a valid Solr doc' do
    path = Rails.root.join('spec', 'fixtures', 'adl', 'texts', 'aakjaer01val.xml')
    # cf = ContentFile.new
    # cf.add_external_file(path.to_s)
    output = DisseminationProfiles::Adl.transform(path.to_s)
    expect {
      Nokogiri::XML(output) { |config| config.strict }
    }.not_to raise_error
  end
end