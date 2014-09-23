require 'nokogiri'
require 'open-uri' # for open to work with URLs

class MediumTop100Feed < Feed
  register_as :medium100, self
  # will extract "url" and "consume_top" from the config.

  def add_news_to_entries
    doc = Nokogiri::HTML(open(@config["url"]))
    # the bloody dynamic loading only gives me the first 10
    canonical = doc.xpath('//head/link[@rel="canonical"]').first['href']
    @canonical = canonical

    doc.css('.block-content').take(@config["consume_top"]).each do |item|
      link = item.css('h3.block-title>a').first
      next if @entries.any? {|e| e[:rel_href] == link['href']} # skip duplicate entries
      @entries << {
        title: link.content,
        reading_time: item.css('.readingTime').first.content,
        rel_href: link['href']
      }
    end
  end

  def meta_for_entries(yielder)
    yielder.yield @canonical, @canonical, @canonical
    @entries.each do |entry|
      yielder.yield entry[:title], entry[:reading_time], "https://medium.com"+entry[:rel_href]
    end
  end
end
