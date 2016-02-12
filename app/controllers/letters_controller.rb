class LettersController < ApplicationController
  def update
    # here we do the letter update
    render text: params['letter'].to_json
  end
end