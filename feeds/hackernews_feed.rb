require 'nokogiri'
require 'open-uri' # for open to work with URLs

class HackernewsFeed < Feed
  register_as :hackernews, self

  # will extract "url" and "consume_top" from the config.
  def add_news_to_entries
    doc = Nokogiri::HTML(open(@config["url"]))
    doc.css('tr>td.title>a').take(@config["consume_top"]).each do |link|
      next if @entries.any? {|e| e[:href] == link['href']} # skip duplicate entries
      @entries << {
        title: link.content,
        href: link['href']
      }
    end
  end
  
  def meta_for_entries(yielder)
    @entries.each do |entry|
      yielder.yield entry[:title], "...", entry[:href]
    end
  end
end