class MixedMaterialsController < ApplicationController
  authorize_resource
  def new
    @mixed_material = MixedMaterial.new
    @mixed_material.titles.build
    @mixed_material.relators.build
    @mixed_material.instances.build
    @instance = @mixed_material.instances.first
  end
end