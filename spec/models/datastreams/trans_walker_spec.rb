# -*- coding: utf-8 -*-
require 'spec_helper'

describe 'trans walker' do
  # let(:id) { '9788711396322' } # Min kamp
#  let(:id_val) { '9780691129785' } # The origin
  let(:id_val) {'001003523'} # Ditlevsen's letters
#  let(:id_type) {'isbn'}
  let(:id_type) {'sys'}

  describe 'Work.from_mods' do
    let(:work) { ConversionService.work_from_aleph(id_type, id_val)}

    it 'should initialize a work from mods ' do
      expect(work).to be_a Work
    end

    it 'should have a title' do
      expect(work.title_values.size).to be > 0
    end

    it 'should create an author for the work' do
      expect(work.authors.size).to be > 0
    end

    it 'should save the author correctly with a display value' do
      expect(work.authors.first.display_value.present?).to eql true
    end
  end

  describe 'Instance.from_mods' do
    let(:instance) { ConversionService.instance_from_aleph(id_type,id_val)}

    it 'should initialize an instance from mods ' do
      expect(instance.publisher.first.present?).to eql true
    end
  end

end
