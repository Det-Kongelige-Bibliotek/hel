class MixedMaterialsController < ApplicationController
  authorize_resource
  def new
    @mixed_material = MixedMaterial.new
  end
end