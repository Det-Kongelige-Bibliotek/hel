module Authority
  class OrganizationsController < BasesController

    private

    def set_klazz
      @klazz = Authority::Organization
    end
  end
end