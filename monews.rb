# Needed:
# bundle install

# - Find / write a server script which scraps sources news every night at the same time and get the top N articles (tagesschau offers a homepage sorted rss, hackernews (best) is sorted, reddit is sorted, medium monthly things are rated)
# - convert these top N articles as RSS feed for each source
# - import this in your favorite rss reader
#
# - Scraper: http://nokogiri.org
# - Uploader: http://net-ssh.github.io/sftp/v2/api/classes/Net/SFTP/Operations/Upload.html

# TODO refactor article list and article into its own file.

# disable HTTPS verification and silence ruby warnings
warn_level = $VERBOSE
$VERBOSE = nil
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
$VERBOSE = warn_level

require 'open-uri' # for open to work with URLs
require 'yaml'
require 'fileutils'

require_relative "core_ext"
require_relative "article"
require_relative "article_list"
require_relative "source/base"
require_relative "source/rss"
require_relative "source/scrape"

def main()
  sources = [
    # TODO remove days to keep from here and put it in spec only.
    # the source does not actually do anything with this info.
    # TODO put the spec in a YAML config file
    Source::RSS.new('tagesschau', 5, 10, 'http://www.tagesschau.de/xml/atom/'), # top 5 articles, keep last 10 days
    Source::Scrape.new('hackernews', 30, 30, 'https://news.ycombinator.com/best') do |doc, count, list|
      doc.css('tr>td.title>a').take(count).each do |link|
        list << Article.new(link.content, "...", link['href'], Date.today)
      end
      list
    end,
    Source::Scrape.new('medium-monthly', 10, 25, 'https://medium.com/top-100') do |doc, count, list|
      # the bloody dynamic loading only gives me the first 10
      canonical = doc.xpath('//head/link[@rel="canonical"]').first['href']
      list << Article.new(canonical, canonical, canonical, Date.today)
      
      doc.css('div.postItem').take(count).each do |item|
        link = item.css('h3.postItem-title>a').first
        reading_time = item.css('.readingTime')
        list << Article.new(link.content, reading_time.first.content, 'https://medium.com'+link['href'], Date.today)
      end
      list
    end,
  ]
  puts "Processing"
  sources.each do |source|
    puts "- #{source.name}"
    cache_path = File.join(File.dirname(__FILE__), "cache", "#{source.name}.yaml")
    rss_path =  File.join(File.dirname(__FILE__), "feeds", "#{source.name}.rss")
    
    past_articles = ArticleList.from_cache(cache_path)
    articles = nil
    begin
      articles = source.fetch()
    rescue Exception => e
      articles = ArticleList.new
      articles << Article.for_error(e.message, e.backtrace.join("\n"))
    end
    articles.merge_uniquely(past_articles) # it is important who is merged with whom, because the date of the articles might differ
    articles.remove_older_than!(Date.today - source.days_to_keep)
    articles.write_rss(source.name, "Top #{source.number_to_consume_at_once} daily articles of #{source.name}.", rss_path)
    articles.write_cache(cache_path)
  end
  puts "done"
end

if __FILE__ == $0 then
  main()
end