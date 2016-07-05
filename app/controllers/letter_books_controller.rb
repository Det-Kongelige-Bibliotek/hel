class LetterBooksController < ApplicationController
  include Concerns::RemoveBlanks
  before_action :set_letter_book, only: [:show, :edit, :update, :facsimile, :begin_work, :complete_work]

  respond_to :html

  def show
    redirect_to solr_document_path(@letter_book)
  end

  def edit
    @letter_book.relators.build(role:'http://id.loc.gov/vocabulary/relators/edt') unless @letter_book.editors.present?
  end

  def update
    if @letter_book.update_work(work_params) && @letter_book.update_instances(instance_params)
      flash[:notice] =  t(:model_updated, model: t('models.letterbook'))
    else
      flash[:error] =  t(:model_update_failed, model: t('models.letterbook'))
    end
    # respond_with @letter_book
    redirect_to solr_document_path(@letter_book)
  end

  def begin_work
    @letter_book.get_instance('TEI').status='working'
  #  @letter_book.get_instance('TIFF').status='working'
    @letter_book.save
    redirect_to solr_document_path(@letter_book)
  end

  def complete_work
    @letter_book.get_instance('TEI').status='completed'
  #  @letter_book.get_instance('TIFF').status='completed'
    @letter_book.save
    redirect_to solr_document_path(@letter_book)
  end

  private

  def set_letter_book
    @letter_book = LetterBook.find(URI.unescape(params[:id]))
  end

  def work_params
    params[:letter_book].permit(:language, :origin_date, titles_attributes: [[:id, :value, :subtitle, :lang, :type, :_destroy]],
                                relators_attributes: [[ :id, :agent_id, :role, :_destroy ]], subjects: [[:id]], note:[]).tap do |fields|
      # remove any inputs with blank values
      fields['titles_attributes'] = fields['titles_attributes'].select {|k,v| v['value'].present? && (v['id'].present? || v['_destroy'] != '1')} if fields['titles_attributes'].present?

      #remove any agents whit blank agent_id
      #remove any agents whith no relator_id and destroy set to true (this happens when a user has added a relator in the interface
      # and deleted it again before saving)
      fields['relators_attributes'] = fields['relators_attributes'].select {|k,v| v['agent_id'].present? && (v['id'].present? || v['_destroy'] != '1')} if fields['relators_attributes'].present?
    end
  end

  def instance_params
    params[:letter_book][:instance].permit(:type, :activity, :title_statement, :extent, :copyright,
                                           :dimensions, :mode_of_issuance, :isbn13, :material_type,
                                           :contents_note, :embargo, :embargo_date, :embargo_condition, :edition,
                                           :publisher, :published_date, :copyright_holder, :copyright_date, :copyright_status,
                                           :access_condition, :availability, :preservation_collection, :note, collection: [],
                                           content_files: [], relators_attributes: [[ :id, :agent_id, :role ]],
                                           publications_attributes: [[:id, :copyright_date, :provider_date ]]).tap { |elems| remove_blanks(elems) }
  end

  def show_letter_and_facsimile
  end

end
