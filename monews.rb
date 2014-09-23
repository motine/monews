# needs RUBY >= 2.0.0p353
# Run `bundle install`

# TODO add setting to spec how often to refresh (e.g. only every 10 hours)
# TODO check that the setting how often to pull in new data is obayed.

require_relative "disable_ssl_warning"

require_relative "core_ext"
require_relative "bowel"
require_relative "feeds/feed"
require_relative "feeds/rss_feed"
require_relative "feeds/hackernews_feed"
require_relative "feeds/medium_top100_feed"

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
    feeds << klass.new(fc["name"], fc["desc"], fc["max_size"], File.dirname(__FILE__), fc)
  end
  return feeds
end

def main()
  config = read_config()
  feeds = instanciate_feeds(config['feeds'])
  feeds.each do |feed|
    feed.process
  end
end

if __FILE__ == $0 then
  main()
end