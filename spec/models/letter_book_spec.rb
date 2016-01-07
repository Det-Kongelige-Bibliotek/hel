# -*- coding: utf-8 -*-
require 'spec_helper'

#let(:aleph_value) {'001003523'} #Brandes
#let(:aleph_value) {'001541111'} # Ditlevsen's letters

describe LetterBook do
  include_context 'shared'
  let(:aleph_value) {'001541111'} # Ditlevsen's letters
  let(:aleph_field) {'sys'}

  it "can create a new Letter Book" do
   lb = LetterBook.new_letterbook(work_params,instance_params)
   lb.save
   expect(lb.instances.size).to eql 2
  end

  it "can update work attributes" do
    lb = LetterBook.new_letterbook(work_params,instance_params)
    lb.save
    new_work_params = work_params
    new_work_params["origin_date"] = "2015"
    lb.update_work(new_work_params)
    expect(lb.origin_date).to eql "2015"
  end

  it "can update instance attributes" do
    lb = LetterBook.new_letterbook(work_params,instance_params)
    lb.save
    new_instance_params = instance_params
    new_instance_params["preservation_collection"] = "storage"
    lb.update_instances(new_instance_params)
    tei = lb.get_instance("TEI")
    expect(tei.preservation_collection).to eql "storage"
    tiff = lb.get_instance("TIFF")
    expect(tiff.preservation_collection).to eql "storage"
  end

  it "can update work attributes from aleph" do
    mods = ConversionService.aleph_to_mods(aleph_field, aleph_value)
    lb = LetterBook.new_letterbook({},{})
    lb.save
    @service = AlephService.new
    set = @service.find_set("sys="+aleph_value) 
    rec = @service.get_record(set[:set_num],set[:num_entries])
    puts rec
    puts mods.to_xml()
    lb.from_mods(mods)
    expect(lb.title_values.first).to include 'Kære Victor'
  end

  it "can update instance attributes from aleph" do
    mods = ConversionService.aleph_to_mods(aleph_field, aleph_value)
    lb = LetterBook.new_letterbook({},{})
    lb.save
    tei = lb.get_instance("TEI")
    # tiff = lb.get_instance("TIFF")
    puts mods.to_xml()
    tei.from_mods(mods)
    # tiff.from_mods(mods) and an instance is an instance is an instance
    expect(tei.publisher_name).to include 'Gyldendal'
  end


end
