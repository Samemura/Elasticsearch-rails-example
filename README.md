# Elasticsearch-rails-example
Example code to use elasticsearch gems.

## Keys

### app/models/concerns/elasticsearchable.rb
This is concern file to search elasticearch, does not implement updating elasticsearch index.  
app/models/example.rb shows how to use.

### lib/tasks/elasticsearch.rake
It provides rake task to create indice / update mapping / upload documents.

## Gems
gem 'elasticsearch', '1.0.15'  
gem 'elasticsearch-rails', '0.1.8'  
gem 'elasticsearch-model', '0.1.8'  
gem 'faraday_middleware-aws-signers-v4'  
