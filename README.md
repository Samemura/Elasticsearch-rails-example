# Elasticsearch-rails-example
Example code to use elasticsearch gems.

## Keys

### app/models/concerns/elasticsearchable.rb
This is concern file to search elasticearch, does not implement updating elasticsearch index.
app/models/example.rb shows how to use.

### lib/tasks/elasticsearch.rake
It provides rake task to create indice / update mapping / upload documents.
