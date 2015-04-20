require 'spec_helper'

describe Administration::ExternalRepositoriesController, :type => :controller do

  let(:valid_attributes) { { name: 'Test Repository' } }

  let(:valid_session) { {}}

  before :each do
    Administration::ExternalRepository.delete_all
  end

  describe 'GET index' do
    it "returns http success" do
      get :index, {}, valid_attributes
      expect(response).to have_http_status(:success)
    end

    it 'assigns all instances as @instances' do
      repo = Administration::ExternalRepository.create(valid_attributes)
      get :index, {}, valid_session
      assigns(:external_repositories).should include repo
    end
  end

  describe "GET show" do
    it "returns http success" do
      repo = Administration::ExternalRepository.create(valid_attributes)
      get :show, { id: repo.to_param }, valid_session
      expect(response).to have_http_status(:success)
    end

    it 'assigns the requested controlled list' do
      repo = Administration::ExternalRepository.create(valid_attributes)
      get :show, { id: repo.to_param }, valid_session
      assigns(:external_repository).should eq(repo)
    end

  end
end
