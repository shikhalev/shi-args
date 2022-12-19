# encoding: utf-8

require_relative "version"

class Shi::Args::Value
  class Variable < Shi::Args::Value
    INTERNAL_PATTERN = /^\{\{\-?\s?(?<variable>[[:alpha:]][\w\.]*)\s?\-?\}\}$/

    attr_reader :variable

    def initialize(source)
      super source
      match = @source.match INTERNAL_PATTERN
      if match
        @variable = match[:variable]
        @braced = true
      else
        @variable = source
        @braced = false
      end
    end

    def braced?
      @braced
    end

    def lookup(context, name)
      lookup = context
      name.split(".").each do |value|
        lookup = lookup[value]
      end
      lookup
    end

    def value
      if @render_context
        lookup @render_context, @variable
      else
        raise ContextError, "No context attached"
      end
    end

    def attach!(render_context)
      @render_context = render_context
    end

    private :lookup
  end

  class String < Shi::Args::Value
    # abstract
  end

  class Path < Shi::Args::Value::String
    def initialize(source)
      super source
      sign = source.slice(0)
      if sign == '@'
        @value = source.slice(1..-1)
        @signed = true
      else
        @signed = false
      end
    end

    def signed?
      @signed
    end
  end

  class Quoted < Shi::Args::Value::String
    attr_reader :qoutes

    def initialize(source)
      super source
      @value = source.slice(1..-2)
      @quotes = case source.slice(0)
        when "'"
          :single
        when '"'
          :double
        end
    end
  end

  class Numeric < Shi::Args::Value
    # abstract
  end

  class Integer < Shi::Args::Value::Numeric
    def initialize(source)
      super source
      @value = source.to_i
    end
  end

  class Float < Shi::Args::Value::Numeric
    def initialize(source)
      super source
      @value = source.to_f
    end
  end

  class Hex < Shi::Args::Value
    attr_reader :raw, :bytes

    def initialize(source)
      super source
      src = source.slice(1..-1)
      @raw = src.to_i(16)
      @bytes = src.each_char.each_slice(2).map { |s| s.join.to_i(16) }
    end
  end

  class WithUnit < Shi::Args::Value
    class Integer < Shi::Args::Value::WithUnit
      INTERNAL_PATTERN = /(?<number>\d+)(?<unit>([[:alpha:]]+|%))/

      def initialize(source)
        super source
        match = @source.match INTERNAL_PATTERN
        if match
          @number = match[:number].to_i
          @unit = match[:unit].intern
        end
      end
    end

    class Float < Shi::Args::Value::WithUnit
      INTERNAL_PATTERN = /(?<number>\d?\.\d+)(?<unit>([[:alpha:]]+|%))/

      def initialize(source)
        super source
        match = @source.match INTERNAL_PATTERN
        if match
          @number = match[:number].to_f
          @unit = match[:unit].intern
        end
      end
    end

    attr_reader :number, :unit
  end

  class Keyword < Shi::Args::Value
    # abstract
  end

  class Boolean < Shi::Args::Value::Keyword
    def initialize(source, value)
      super source
      @value = value
    end
  end

  class Flag < Shi::Args::Value::Boolean
    def initialize
      super nil, true
    end
  end

  class Nil < Shi::Args::Value::Keyword
    def initialize
      super "nil"
      @value = nil
    end
  end

  attr_reader :source, :value

  def initialize(source)
    @source = source
    @value = source
  end

  def to_s
    @source
  end
end
