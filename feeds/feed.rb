require 'yaml'
require 'fileutils'

# Note: Feed does not make any assumptions about the format of each individual entry.
class Feed
  attr_reader :name, :desc, :max_size, :base_path, :config
  def initialize(name, desc, max_size, base_path, config)
    @name = name
    @desc = desc
    @max_size = max_size
    @base_path = base_path
    @config = config
    @error = nil
  end
  
  def process
    @entries = Bowel.new(@max_size)
    self.add_cache_to_entries()
    begin
      self.add_news_to_entries()
    rescue Exception => e
      @error = [e.message, e.backtrace.join("\n")]
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

    entry_spec_enum = nil
    if @error.nil? then
      entry_spec_enum = Enumerator.new { |yielder| self.meta_for_entries(yielder) }
    else
      entry_spec_enum = Enumerator.new { |yielder| yielder.yield "#{Date.today.to_s} ERROR #{@error[0]}", @error[1], "about:none" }
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
    File.join(@base_path, "tmp", "cache", "#{@name.path_safe}.yaml")
  end
  def cache_path!
    FileUtils.mkdir_p(File.dirname(self.cache_path)) unless File.directory?(File.dirname(self.cache_path))
  end
  def rss_path
    File.join(@base_path, "rss", "#{@name.path_safe}.rss")
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

