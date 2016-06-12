require 'faraday_middleware/aws_signers_v4'

credentials = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
client = Elasticsearch::Client.new url: "https://#{ENV['ELASTIC_SEARCH_HOST']}", request_timeout: 2 do |f|
  f.request :aws_signers_v4, credentials: credentials,
                             service_name: 'es', region: 'ap-northeast-1'
end

Elasticsearch::Model.client = client
