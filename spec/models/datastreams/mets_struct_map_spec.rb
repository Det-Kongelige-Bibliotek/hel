# -*- coding: utf-8 -*-
require 'spec_helper'

describe Datastreams::MetsStructMap do
  before :each do
    file = File.new('./spec/fixtures/aarebo_mets_structmap_sample.xml')
    @ds = Datastreams::MetsStructMap.from_xml(file)
  end

  it 'should have ordered files' do
    files = @ds.ordered_files
    files.size.should eql 6
    files['1'].should eql 'arre1fm001.tif'
    files['2'].should eql 'arre1fm002.tif'
    files['3'].should eql 'arre1fm003.tif'
    files['4'].should eql 'arre1fm004.tif'
    files['5'].should eql 'arre1fm005.tif'
    files['6'].should eql 'arre1fm006.tif'
  end

  it 'should be able to add an ordered file' do

    @ds.add_file("7","arre1fm007.tif")
    @ds.ordered_files.should include({'7' => 'arre1fm007.tif'})
  end
end