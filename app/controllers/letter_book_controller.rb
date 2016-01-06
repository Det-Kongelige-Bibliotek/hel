class LetterBookController < ApplicationController
  include Concerns::RemoveBlanks
  before_action :set_letter_book, only: [:show, :edit, :update]

  def show

  end

  def edit

  end

  def update

  end

  private

  def set_letter_book
    @letter_book = LetterBook.find(URI.unescape(params[:id]))
  end

  def work_params



  end

  def instance_params

  end

end