# -*- coding: utf-8 -*-
require 'spec_helper'

describe 'trans walker' do
  
  before do
    @service = AlephService.new
    #set = @service.find_set("isbn=9788711396322") Min kamp
    set = @service.find_set("isbn=9780691129785") # The origin
    # set = @service.find_set("sys=001629300")

    rec = @service.get_record(set[:set_num],set[:num_entries])
    @converter = ConversionService.new(rec)
    doc = @converter.to_mods("")
    @mods = Datastreams::Mods.from_xml(doc)
  end

  it 'should initialize a work from mods ' do
    w=Work.new
    w.from_mods(@mods)
    w.title_values.first.should == 'The  origin then and now'
  end



  it 'should initialize an instance from mods ' do
    i=Instance.new
    i.from_mods(@mods)
    i.isbn13.should == "9780691129785"
  end

end
