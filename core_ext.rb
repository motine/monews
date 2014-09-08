class String
  def sani
    # self.encode('UTF-8', :xml => :text, :invalid => :replace, :undef => :replace, :replace => '')
    self.encode(:xml => :text)
  end
end
