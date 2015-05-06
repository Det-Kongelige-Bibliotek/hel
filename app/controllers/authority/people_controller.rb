module Authority
  # Get most functionality from BasesController
  class PeopleController < Authority::BasesController
    def destroy
      @authority_object.destroy
      respond_to do |format|
        format.html { redirect_to authority_people_path, notice: t('authority.people.destroyed') }
        format.json { head :no_content }
      end
    end

    private

    def set_klazz
      @klazz = Authority::Person
    end

    def authority_base_params
      params.require(:authority_person).permit(:given_name, :family_name, :name,
                                               :same_as, :description, :birth_date, :death_date
      )
    end
  end
end
