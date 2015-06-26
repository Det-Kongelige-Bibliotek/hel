module Authority
  # Get most functionality from BasesController
  class PeopleController < Authority::BasesController
    include Concerns::RemoveBlanks
    def destroy
      @authority_object.destroy
      respond_to do |format|
        format.html { redirect_to authority_people_path, notice: t('authority.people.destroyed') }
        format.json { head :no_content }
      end
    end

    def viaf
      reader = RDF::Reader.open(params[:url])
      stats = reader.each_statement.to_a

      unless stats.empty?
        first_name = stats.select {|s| s.predicate == 'http://schema.org/givenName' }.first.object.value
        family_name = stats.select {|s| s.predicate == 'http://schema.org/familyName' }.first.object.value
        alternate_name = stats.select {|s| s.predicate == 'http://schema.org/alternateName' }.first.object.value
        isni_uri = stats.select {|s| s.predicate == 'http://schema.org/sameAs' and
                                    s.object.value.include? 'http://isni.org/isni/'}.first.object.value
      end

      json_file = {:first_name => first_name, :family_name => family_name, :alternate_name => alternate_name,
                    :isni_uri => isni_uri}

      logger.info json_file
      render json: json_file.to_json
    end


    private

    def set_klazz
      @klazz = Authority::Person
    end

    def authority_base_params
      params.require(:authority_person).permit(:given_name, :family_name, :name,
                                               :description, :birth_date, :death_date,
                                               same_as_uri:[]
      ).tap { |elems| remove_blanks(elems) }
    end
  end
end
