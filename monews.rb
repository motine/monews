# puts RUBY_VERSION
# Needed:
# bundle install

# - Find / write a server script which scraps sources news every night at the same time and get the top N articles (tagesschau offers a homepage sorted rss, hackernews (best) is sorted, reddit is sorted, medium monthly things are rated)
# - convert these top N articles as RSS feed for each source
# - import this in your favorite rss reader
#
# - Scraper: http://nokogiri.org
# - Uploader: http://net-ssh.github.io/sftp/v2/api/classes/Net/SFTP/Operations/Upload.html

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
# require_relative "article"
# require_relative "article_list"
# require_relative "source/base"
# require_relative "source/rss"
# require_relative "source/scrape"

# Bowel behaves like a ring buffer.
# The << operator adds an element to the top and removes the last element if necessary.
class Bowel < Array
  attr_reader :max_size
  def initialize(max_size, enum = nil)
    @max_size = max_size
    enum.each { |e| self << e } if enum
  end

  def <<(elm)
    if self.size < @max_size then
      self.unshift(elm)
    else
      self.pop # remove last
      self.unshift(elm)
    end
  end
end

# Note: Feed does not make any assumptions about the format of each individual entry.
class Feed
  attr_reader :name, :desc, :max_size, :base_path, :config
  def initialize(name, desc, max_size, base_path, config)
    @name = name
    @desc = desc
    @max_size = max_size
    @base_path = base_path
    @config = config
  end
  
  def process
    @entries = Bowel.new(@max_size)
    self.add_cache_to_entries()
    begin
      self.add_news_to_entries()
    rescue Exception => e
      raise e
      # TODO error handling
      # puts "  ERROR #{e.message}: #{e.backtrace.join("\n")}"
      # articles << Article.for_error(e.message, e.backtrace.join("\n"))
      # Article.new("[#{Date.today.to_s} ERROR] #{title}", summary, "...", Date.today)
    end
    self.write_cache()
    self.write_rss()
  end
  
  # To be overwritten in the subclass
  def add_news_to_entries
    raise "Implement me in subclass!"
  end
  # Call `yielder.yield mytitle, mydesc, mylink` for each entry in the @entries model.
  def meta_for_entries(yielder)
    raise "Implement me in subclass!"
  end
  
  # ---
  # Cache handling
  def add_cache_to_entries
    cached = YAML.load_file(cache_path) rescue [] # ignore if there is no valid file
    cached.each do |entry|
      @entries.push(entry) # we must use push here to preserve the order, not <<.
    end
  end
  def write_cache
    self.cache_path!
    File.open(self.cache_path, 'w') do |f|
      f.write YAML.dump(@entries.to_a)
    end
  end
  # ---
  # RSS export
  def write_rss
    rss = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
    rss << "<rss version=\"2.0\">\n"
    rss << "<channel>\n"
    rss << "  <title>#{@name.sani}</title>\n"
    rss << "  <description>#{@desc.sani}</description>\n"

    entry_spec_enum = Enumerator.new do |yielder|
      self.meta_for_entries(yielder)
    end
    
    rss << entry_spec_enum.collect do |title, desc, link|
      er = "  <item>\n"
      er << "    <title>#{title.sani}</title>\n"
      er << "    <link>#{link.sani}</link>\n"
      er << "    <description>#{desc.sani}</description>\n"
      er << "  </item>\n"
    end.join("\n")

    rss << "</channel>\n"
    rss << "</rss>\n"

    self.rss_path!
    File.open(self.rss_path, 'w:UTF-8') do |f|
      f.write(rss.encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => ''))
    end
  end
  
  # ---
  # Path helper
  def cache_path
    File.join(@base_path, "cache", "#{@name.path_safe}.yaml")
  end
  def cache_path!
    FileUtils.mkdir_p(File.dirname(self.cache_path)) unless File.directory?(File.dirname(self.cache_path))
  end
  def rss_path
    File.join(@base_path, "feeds", "#{@name.path_safe}.rss")
  end
  # creates the directory for rss files
  def rss_path!
    FileUtils.mkdir_p(File.dirname(self.rss_path)) unless File.directory?(File.dirname(self.rss_path))
  end
  
  # ---
  # Registry/Factory methods to instanciate objects by names. The names come from the config file
  def self.register_as(type_name, klass)
    @@registered_feed_types ||= {}
    @@registered_feed_types[type_name.to_sym] = klass
  end
  
  def self.class_for(type_name)
    return @@registered_feed_types[type_name.to_sym]
  end
end



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

require 'nokogiri'
require 'open-uri' # for open to work with URLs

class MediumTop100 < Feed
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


def fatal_error(message, code=1)
  $stderr.puts message
  Kernel.exit(code)
end

def read_config
  config_path = File.join(File.dirname(__FILE__), "config.yaml")
  begin
    return YAML.load_file(config_path)
  rescue Exception => e
    raise e
    fatal_error("There is something wrong with the config file. Please make sure you have #{config_path} and it is similar to config.yaml.example.")
  end
end

def instanciate_feeds(feeds_config)
  feeds = []
  feeds_config.each do |fc|
    klass = Feed::class_for(fc["type"])
    fatal_error("The type '#{fc["type"]}' for #{fc["name"]} could not be instanciated. Spelling mistake?") if klass.nil?
    feeds << klass.new(fc["name"], fc["desc"], fc["max_size"], File.join(File.dirname(__FILE__), "tmp"), fc)
  end
  return feeds
end

def main()
  # TODO add setting to spec how often to refresh (e.g. only every 10 hours)
  # TODO check that the setting how often to pull in new data is obayed.
  # TODO error handling in process

  config = read_config()
  feeds = instanciate_feeds(config['feeds'])
  feeds.each do |feed|
    feed.process
  end
end

if __FILE__ == $0 then
  main()
end