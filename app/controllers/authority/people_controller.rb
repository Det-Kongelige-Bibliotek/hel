module Authority
  # Get most functionality from BasesController
  class PeopleController < Authority::BasesController
    def destroy
      @authority_object.destroy
      respond_to do |format|
        format.html { redirect_to authority_people_path, notice: 'Person was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_klazz
      @klazz = Authority::Person
    end

    def authority_base_params
      params.require(:authority_person).permit(authorized_personal_name: [
        [:scheme, :full, :family, :given, :date]
      ])
    end
  end
end
