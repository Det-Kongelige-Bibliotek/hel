require 'spec_helper'

describe MixedMaterials do
  let (:archive) { MixedMaterials.new }
  let (:instance) { Instance.new }

  it 'should be possible to add instances' do
    expect(archive.respond_to?(:instances)).to eql true
    expect { archive.instances += [instance] }.not_to raise_error
  end
end