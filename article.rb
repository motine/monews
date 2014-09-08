class Article
  attr_accessor :title, :summary, :link, :date
  def initialize(title, summary, link, date)
    @title, @summary, @link, @date = title, summary, link, date
  end
  
  def self.for_error(title, summary)
    return Article.new("[#{Date.today.to_s} ERROR] #{title}", summary, "...", Date.today)
  end
  
  def is_similar?(other_article)
    return other_article.link == self.link
  end

  def older_than?(date)
    return @date.to_date < date
  end

  def rss_item
    result =  "  <item>\n"
    result << "    <title>#{@title.sani}</title>\n"
    result << "    <link>#{@link.sani}</link>\n"
    result << "    <description>#{@summary.sani}</description>\n"
    result << "  </item>\n"
    return result
  end
end