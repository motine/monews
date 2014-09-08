# needed:
# bundle install

# - Find / write a server script which scraps sources news every night at the same time and get the top N articles (tagesschau offers a homepage sorted rss, hackernews (best) is sorted, reddit is sorted, medium monthly things are rated)
# - convert these top N articles as RSS feed for each source
# - import this in your favorite rss reader
#
# - Write a scraper / reader which uploads the content up to a Amazon S3 storage
# - Use Amazon S3 for storage (RSS feeds)?
#
#
#
# - Scraper: http://nokogiri.org
# - Feed Generator: http://ruby-doc.org/stdlib-1.9.3/libdoc/rss/rdoc/RSS/Maker.html
# - Uploader: http://net-ssh.github.io/sftp/v2/api/classes/Net/SFTP/Operations/Upload.html


require 'open-uri' # for open to work with URLs
require 'yaml'
require 'fileutils'

require_relative "source/base"
require_relative "source/rss"
require_relative "source/scrape"

# disable HTTPS verification
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE


class Article
  attr_accessor :title, :summary, :link, :date
  def initialize(title, summary, link, date)
    @title, @summary, @link, @date = title, summary, link, date
  end
  
  def is_similar?(other_article)
    return other_article.link == self.link
  end

  def older_than?(date)
    return @date.to_date < date
  end

  def rss_item
    result =  "  <item>\n"
    result << "    <title>#{@title}</title>\n"
    result << "    <link>#{@link}</link>\n"
    result << "    <description>#{@summary}</description>\n"
    result << "  </item>\n"
    return result
  end
end

class ArticleList

  attr_accessor :articles

  def initialize
    @articles = []
  end
  
  def self.from_cache(path)
    instance = self.new()
    begin
      instance.articles = YAML.load_file(path)
    rescue
      # ignore if there is no valid file
    end
    return instance
  end
  
  def write_cache(path)
    FileUtils.mkdir_p(File.dirname(path)) unless File.directory?(File.dirname(path))
    File.open(path, 'w') do |f|
      f.write YAML.dump(@articles)
    end
  end
  
  def merge_uniquely(other)
    other.each do |other_article|
      self << other_article if @articles.none? {|article| other_article.is_similar?(article)}
    end
  end
  
  def remove_older_than!(date)
    @articles.delete_if do |article|
      article.older_than?(date)
    end
  end

  def write_rss(title, about, path)
    FileUtils.mkdir_p(File.dirname(path)) unless File.directory?(File.dirname(path))

    rss = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
    rss << "<rss version=\"2.0\">\n"
    rss << "<channel>\n"
    rss << "  <title>#{title}</title>\n"
    rss << "  <description>#{about}</description>\n"
    @articles.each do |article|
      rss << article.rss_item()
    end
    rss << "</channel>\n"
    rss << "</rss>\n"
    File.open(path, 'w:UTF-8') do |f|
      f.write(rss.encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => ''))
    end
  end
  
  def [](i)
    return @articles[i]
  end
  def <<(article)
    @articles << article
  end
  def each(&block)
    @articles.each do |article|
      block.call(article)
    end
  end
end

def main()
  sources = [
    # remove days to keep from here and put it in spec only.
    # the source does not actually do anything with this info.
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
        # TODO make URL absoulute
      end
      list
    end,
  ]
  
  sources.each do |source|
    cache_path = File.join(File.dirname(__FILE__), "cache", "#{source.name}.yaml")
    rss_path =  File.join(File.dirname(__FILE__), "feeds", "#{source.name}.rss")
    
    past_articles = ArticleList.from_cache(cache_path)
    # TODO do some error handling here
    articles = source.fetch()
    articles.merge_uniquely(past_articles) # it is important who is merged with whom, because the date of the articles might differ
    articles.remove_older_than!(Date.today - source.days_to_keep)
    articles.write_rss(source.name, "Top #{source.number_to_consume_at_once} daily articles of #{source.name}.", rss_path)
    articles.write_cache(cache_path)
  end
end

main()