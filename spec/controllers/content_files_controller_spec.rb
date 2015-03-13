require 'spec_helper'

describe ContentFilesController, type: :controller do

  let(:valid_session) { {} }

  before :each do
    Authority::Base.delete_all
    login_admin
  end

  describe '#upload' do
    it 'should show file upload page' do
      cf = ContentFile.new
      cf.edit_groups = ['Chronos-Admin']
      cf.save
      get :upload, {id: cf.pid}, valid_session
      expect(assigns(:file)).to eql cf
    end
  end

  describe '#update' do
    it 'should replace content' do
      agent2 = Authority::Person.create(
          authorized_personal_name: { given: 'Fornavn2', family: 'Efternavn2', scheme: 'KB' }
      )
      #work_attributes = {titles: {'0' => {'value'=> 'Another work title'} }, creators: {'0'=>{'id'=> agent2.id, 'type'=>'aut'} } }
      w = Work.new
      w.save(validate: false)
      activity = Administration::Activity.create(activity: "ADL", embargo: "0", access_condition: "",
                                                    copyright: "Attribution-NonCommercial-ShareAlike CC BY-NC-SA", collection: "dasam3", preservation_profile: "storage")
      activity.permissions = {"file"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"]}},
                                  "instance"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-Alle"], "edit"=>["Chronos-NSA","Chronos-Admin"]}}}
      activity.save
      instance_attributes = { activity: activity.id, copyright: 'Some Copyright',  collection: 'Some Collection'}
      i = Instance.new instance_attributes
      i.set_work=w
      i.save
      cf = i.add_file(Rails.root.join('spec','fixtures','holb06valid.xml').to_s)
      cf.edit_groups = ['Chronos-Admin']
      cf.save
      i.save
      new_file = fixture_file_upload('holb06valid2.xml')

      post :update, {id: cf.pid, file: new_file}, valid_session

      cf.reload
      new_checksum = Digest::MD5.file(new_file).hexdigest
      expect(cf.checksum).to eql new_checksum

    end
  end
end