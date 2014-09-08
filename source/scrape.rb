require 'nokogiri'
require 'open-uri' # for open to work with URLs

module Source
  class Scrape < Source::Base
    attr_accessor :url, :scrape_code
    def initialize(name, number_to_consume_at_once, days_to_keep, url, &scrape_code)
      super(name, number_to_consume_at_once, days_to_keep)
      @url = url
      @scrape_code = scrape_code
    end

    def fetch
      result = ArticleList.new
      
      doc = Nokogiri::HTML(open(@url))
      return @scrape_code.call(doc, number_to_consume_at_once, result)
    end
  end
end