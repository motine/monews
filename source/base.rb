module Source
  class Base
    attr_accessor :name, :number_to_consume_at_once, :days_to_keep

    def initialize(name, number_to_consume_at_once, days_to_keep)
      @name = name
      @number_to_consume_at_once = number_to_consume_at_once
      @days_to_keep = days_to_keep
    end
    
    def fetch
      raise 'Not implemented'
    end
  end
end