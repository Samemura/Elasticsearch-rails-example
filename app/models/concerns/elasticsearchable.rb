# https://www.elastic.co/guide/en/elasticsearch/reference/2.2/query-dsl-bool-query.html
#
# Eg. Job.__elasticsearch__.search({query: { match_all: {} }}).results.total
#
# gem 'elasticsearch-dsl' is not working correctly and not big benefit so did not use.
# known bug:
# - filter query for bool query is not implemented
# - pagination cannot be working and no tips on thw web.

module Elasticsearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    class << self
      def elasticsearch(index, search_words: nil, and_or_filters: nil, or_and_filters: nil, range_filters: nil, not_filters: nil,
                        page: 1, per_page: 50, aggs: nil, agg_size: 0, sort: nil)
        must_query = []
        must_query += get_search_words_query(search_words)
        must_query += get_and_or_filters_query(and_or_filters)
        must_query += get_or_and_filters_query(or_and_filters)
        must_query += get_range_filters_query(range_filters)

        must_not_query = []
        must_not_query += get_and_or_filters_query(not_filters)

        query = { query: { bool: { must: must_query, must_not: must_not_query } } }

        if per_page.present?
          query[:size] = per_page
          if page.present? && (page > 0)
            from_no = (page - 1) * per_page
            query[:from] = from_no
          end
        end

        query[:sort] = [sort] if sort.present?
        query.merge!(get_aggs_query(aggs, agg_size)) if aggs.present?

        __elasticsearch__.search(query, index: index)
      end

      private

      def get_search_words_query(search_words)
        query = []
        if search_words.present?
          search_words.each do |key, val|
            query.push(multi_match: { query: key, fields: val })
          end
        else
          query.push(match_all: {})
        end
        query
      end

      def get_and_or_filters_query(filters)
        query = []
        if filters.present?
          Array(filters).each do |filter|
            should_query = []
            filter.each_pair do |key, val|
              should_query.push(term: { key => val }) if val.present?
            end
            query.push(bool: { should: should_query }) if should_query.present?
          end
        end
        query
      end

      def get_or_and_filters_query(filters)
        query = []
        if filters.present?
          should_query = []
          Array(filters).each do |and_filter|
            m_q = []
            and_filter.each do |key, val|
              m_q.push(term: { key => val }) if val.present?
            end
            should_query.push(bool: { must: m_q }) if m_q.present?
          end
          query.push(bool: { should: should_query }) if should_query.present?
        end
        query
      end

      def get_range_filters_query(filters)
        query = []
        if filters.present?
          Array(filters).each do |filter|
            query.push(range: filter) if filter.present?
          end
        end
        query
      end

      def get_aggs_query(arr, size)
        agg = {}
        if arr[0].present?
          agg = {
            aggregations: {
              agg_hits: {
                terms: { field: arr[0], size: size } # size = 0 means Integer.MAX_VALUE. https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html#_size
              }
            }
          }
          agg[:aggregations][:agg_hits].merge! get_aggs_query(arr.drop(1), size)
        end
        agg
      end
    end
  end
end
