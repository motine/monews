require 'feedjira'
# for available element attributes in feedjira see https://github.com/feedjira/feedjira/blob/master/lib/feedjira/parser/rss_entry.rb

class RssFeed < Feed
  register_as :rss, self
  
  # will extract "url" and "consume_top" from the config.
  def add_news_to_entries
    feed = Feedjira::Feed.fetch_and_parse(config["url"])
    feed.entries.take(@config["consume_top"].to_i).each do |entry|
      next if @entries.any? {|e| e[:link] == entry.url} # skip duplicate entries
      @entries << { 
        title: entry.title,
        summary: entry.summary,
        link: entry.url
      } # entry.published
    end
  end
  
  def meta_for_entries(yielder)
    @entries.each do |entry|
      yielder.yield entry[:title], entry[:summary], entry[:link]
    end
  end
end