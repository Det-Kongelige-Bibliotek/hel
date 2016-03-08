# -*- coding: utf-8 -*-
require 'spec_helper'
require 'fakeredis'
require 'resque'

describe 'ingest a letter_book' do
  include_context 'shared'

  before :all do

    activity = Administration::Activity.create
    (
     {
       activity: 'Danmarks Breve',
       embargo:  '1',
       access_condition:'',
       copyright: 'CC BY-NC-ND',
       preservation_collection: 'storage',
       availability: '',
       collection: ["dasam3"],
       activity_permissions:
       {
         "file"=>{
           "group"=>{"discover"=>["Chronos-Alle"],
             "read"=>["Chronos-Alle"],
             "edit"=>["Chronos-Alle"] }
         },
         "instance"=>{
           "group"=>{"discover"=>["Chronos-Alle"],
             "read"=>["Chronos-NSA","Chronos-Admin"],
             "edit"=>["Chronos-NSA","Chronos-Admin"]
           }
         }
       }
     }
     )
  end

  describe 'tei file' do
    it 'it should read an xml file' do 
      lb_id=LetterBookIngest.perform("spec/fixtures/breve/001541111_000/001541111_000.xml",
                                     "spec/fixtures/breve/001541111_000/")
      puts lb_id
      lb = Work.find(lb_id)
      puts lb.title_values.first
      expect(lb.title_values.first).to include 'Victor'
    end
  end

end

