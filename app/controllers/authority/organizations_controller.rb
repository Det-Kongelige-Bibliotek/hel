module Authority
  class OrganizationsController < BasesController
    authorize_resource

    private

    def set_klazz
      @klazz = Authority::Organization
    end

    def authority_base_params
      params.require(:authority_organization).permit(:_name, :founding_date, :dissolution_date, location: [])
    end

  end
end