require 'spec_helper'

describe DisseminationProfiles::Adl do
  include_context 'shared'

  let(:sample_work) { Work.create(work_params)}
  let(:instance) do
    i = Instance.new(instance_params)
    i.work = sample_work
    path = Rails.root.join('spec', 'fixtures', 'adl', 'texts', 'aakjaer01val.xml')
    i.type = 'TEI'
    i.save
    i.add_file(path.to_s, [], false)
    i.save
    i
  end
  # Given an ADL tei file
  # When I call transform on DisseminationProfiles::ADL
  # It will produce the correct Solr output
  it 'should produce a valid Solr doc' do
    DisseminationProfiles::Adl.disseminate(instance)
    DisseminationProfiles::Adl.disseminate(instance)
  end
end