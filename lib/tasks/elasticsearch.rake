namespace :elasticsearch do
  # http://www.rubydoc.info/gems/elasticsearch-api

  desc "Create index."
  task :create_index, [:index, :setting_file, :option_force] => :environment do |task, args|
    index_name = args[:index]
    index_setting = YAML.load_file(args[:setting_file])

    if es_client.indices.exists?(index: index_name)
      if args[:option_force].blank?
        puts "Aborted. index: #{index_name} already exists."
        puts
        next
      else
        es_client.indices.delete index: index_name
      end
    end

    es_client.indices.create index: index_name, body: index_setting
    es_client.indices.refresh index: index_name

    puts "index: #{index_name} created."
    puts
  end

  desc "Delete index."
  task :delete_index, [:index] => :environment do |task, args|
    index_name = args[:index]
    es_client.indices.delete index: index_name

    puts "index: #{index_name} deleted."
    puts
  end

  desc "List index."
  task :list_index => :environment do |task, args|
    puts es_client.cat.indices v:true
    puts
  end

  desc "Import document"
  task :import_document, [:index, :mapping, :document_file, :option_force] => :environment do |task, args|
    index_name = args[:index]
    mapping_name = args[:mapping]
    documents=SmarterCSV.process(args[:document_file], file_encoding: 'utf-8', remove_empty_values: false)

    if args[:option_force].blank? && (es_client.count(index: index_name)["count"] > 0)
      puts "Aborted. documents: #{index_name}/#{mapping_name} already exists."
      puts
      next
    end

    puts "importing documents: #{index_name}/#{mapping_name} ..."
    i = 0
    documents.drop(1).each do |doc| # documents[0] is Japanese headder for just reference to person.
      i+=1
      doc[:timestamp] = Date.today.strftime("%Y/%m/%d")
      es_client.index index: index_name, type: mapping_name, id: i, body: doc
    end
    es_client.indices.refresh index: index_name

    puts "#{i.to_s} documents imported."
    puts
  end

  desc "Setup mock data"
  task :setup_mock_data, [:option_index, :option_force, :option_data_dir] => :environment do |task, args|
    INDEX_FILE = "index.yml"
    dir = args[:option_data_dir] || "db/mock/elasticsearch"

    directories = Dir.glob(Rails.root+dir+"*/")
    directories.select!{|d| d.index(args[:option_index]) } if args[:option_index].present?

    directories.each do |dir|
      index = File::basename(dir)
      Rake::Task["elasticsearch:create_index"].invoke(index, dir+INDEX_FILE, args[:option_force])
      Rake::Task["elasticsearch:create_index"].reenable
      Dir.glob(dir+"*.csv").each do |csv|
        mapping = File::basename(csv, ".*")
        Rake::Task["elasticsearch:import_document"].invoke(index, mapping, csv, args[:option_force])
        Rake::Task["elasticsearch:import_document"].reenable
      end
    end

    puts "mock data setupped."
    puts
  end

  private

  def es_client
    @es_client ||= Elasticsearch::Model.client
  end
end
