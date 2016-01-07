require 'spec_helper'

describe LetterBook do
  include_context 'shared'

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

end