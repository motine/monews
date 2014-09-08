require 'feedjira'
# for available element attributes in feedjira see https://github.com/feedjira/feedjira/blob/master/lib/feedjira/parser/rss_entry.rb
require 'open-uri' # for open to work with URLs

module Source
  class RSS < Source::Base
    
    attr_accessor :url
    def initialize(name, number_to_consume_at_once, days_to_keep, url)
      super(name, number_to_consume_at_once, days_to_keep)
      @url = url
    end

    def fetch
      result = ArticleList.new
      feed = Feedjira::Feed.fetch_and_parse(@url)
      feed.entries.take(number_to_consume_at_once).each do |entry|
        result << Article.new(entry.title, entry.summary, entry.url, entry.published)
      end
      return result
    end
  end
end