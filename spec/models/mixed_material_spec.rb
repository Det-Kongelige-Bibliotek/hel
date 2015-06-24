require 'spec_helper'

describe MixedMaterial do
  let (:archive) { MixedMaterial.new }
  let (:instance) { Instance.new }

  it 'should be possible to add instances' do
    expect(archive.respond_to?(:instances)).to eql true
    expect { archive.instances += [instance] }.not_to raise_error
  end
end