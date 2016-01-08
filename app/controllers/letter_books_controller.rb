class LetterBooksController < ApplicationController
  include Concerns::RemoveBlanks
  before_action :set_letter_book, only: [:show, :edit, :update]

  respond_to :html

  def show

  end

  def edit

  end

  def update
    if @letter_book.update_work(work_params) && @letter_book.update_instances(instance_params)
      flash[:notice] =  t(:model_updated, model: t('models.letter_book'))
    end
    respond_with @letter_book
  end

  private

  def set_letter_book
    @letter_book = LetterBook.find(URI.unescape(params[:id]))
  end

  def work_params
    params[:letter_book].permit( :origin_date, titles_attributes: [[:id, :value, :subtitle, :lang, :type]])
  end

  def instance_params
    params[:letter_book][:instance].permit( :edition, :note)
  end

end