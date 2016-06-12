class example < ActiveRecord::Base
  include Elasticsearchable
  class NotFound < StandardError; end

#  DEFAULT is like as yml:
#    default:
#    page_size: 30
#    aggs_query: ['prefecture', 'city']
#    sort_query:
#      key: 'priority'
#      order: 'desc'

  class << self
    def search (index, search_words: nil, and_or_filters: nil, or_and_filters: nil, range_filters: nil, not_filters: nil,
                        page: 1, per_page: DEFAULT.page_size, aggs: DEFAULT.aggs_query, sort: {DEFAULT.sort_query.key => DEFAULT.sort_query.order})
      resp = self.elasticsearch(
        index,
        search_words: search_words,
        and_or_filters: and_or_filters,
        or_and_filters: or_and_filters,
        range_filters: range_filters,
        not_filters: not_filters,
        aggs: aggs,
        page: page,
        per_page: per_page,
        sort: sort
      )
      hits = {hit: resp.results.total}
      hits.merge!(get_hits(resp.aggregations)) if resp.aggregations.present?

      return resp.results, hits
    end

    def find_by_ids(index, ids)
      filter_ids = []
      return [] if ids.blank?

      Array(ids).each do |id|
        filter_ids << {'_id': id}
      end
      self.search(index, or_and_filters: filter_ids)[0]
    end

    private

    def get_hits(aggs)
      hits = Hash.new { |h, k| h[k] = Hash.new(0) }
      aggs[:agg_hits][:buckets].each do |a|
        hits[a[:key]][:hit] = a[:doc_count]
        hits[a[:key]].merge! get_hits(a) if a[:agg_hits].present?
      end
      hits
    end
  end
end
