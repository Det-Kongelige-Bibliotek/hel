require 'spec_helper'

describe 'Snippet Server' do

  id = '001003523_000#L0010035230000001'
  opts={}
  opts[:c] = '/db/letter_books/001003523'

  describe 'render html' do
    it 'return an html page' do
      opts[:op] = 'render'
      html = SnippetServer.render_snippet(id, opts)
      expect(html).to start_with '<div class'
      expect(html).to end_with '</div>'
    end
  end

  describe 'solrize' do
    it 'return a solr document with one work/letter' do
      opts[:op] = 'solrize'
      solr_doc = SnippetServer.render_snippet(id, opts)
      count_trunk = solr_doc.scan(/>trunk</).count
      expect(solr_doc).to start_with '<add>'
      expect(solr_doc).to end_with '</add>'
      expect(count_trunk).to eq 1
    end
  end
end