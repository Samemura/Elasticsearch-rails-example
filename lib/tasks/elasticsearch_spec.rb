require 'rails_helper'
require 'rake'

describe 'Elasticsearch' do

  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require 'tasks/elasticsearch'
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    @rake[task].reenable
  end

  describe 'create_index' do
    let(:task) { 'elasticsearch:create_index' }
    let(:index) { "kayac" }
    let(:setting_file) { "db/mock/elasticsearch/kayac/index.yml"}

    it 'should success.' do
      expect(@rake[task].invoke(index, setting_file)).to be_truthy
    end
  end

  describe 'import_docment' do
    let(:task) { 'elasticsearch:import_document' }
    let(:index) { "kayac" }
    let(:mapping) { "job" }
    let(:document_file) { "db/mock/elasticsearch/kayac/job.csv" }

    it 'should success.' do
      expect(@rake[task].invoke(index, mapping, document_file)).to be_truthy
    end
  end
end
