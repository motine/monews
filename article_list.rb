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
    rss << "  <title>#{title.sani}</title>\n"
    rss << "  <description>#{about.sani}</description>\n"
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
