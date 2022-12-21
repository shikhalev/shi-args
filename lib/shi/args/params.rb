# encoding: utf-8

require_relative 'version'
require_relative 'values'

class Shi::Args::Params
  class << self
    def parse(context, markup)
      obj = self.new context
      obj.parse! markup
    end
  end

  def initialize(context)
    @context = context
    @params = []
    @attrs = {}
  end

  ESCAPES = {
    "\\'" => "(#SINGLE#)",
    '\"' => "(#DOUBLE#)",
    '\ ' => "(#SPACE#)",
  }

  def escape(str)
    return nil if str.nil?
    result = str
    ESCAPES.each do |key, value|
      result.gsub!(key, value)
    end
    return result
  end

  def descape(str)
    return nil if str.nil?
    result = str
    ESCAPES.each do |key, value|
      result.gsub!(value, key)
    end
    return result
  end

  private :escape, :descape

  def parse_value(source)
    Shi::Args::Value::parse @context, source
  end

  def add_key!(name)
    name = name.intern
    value = true
    @params << { name: name, value: value }
    @attrs[name] = value
  end

  def add_param!(source)
    @params << { value: parse_value(source) }
  end

  def add_attr!(name, source)
    name = name.intern
    value = parse_value(source)
    @params << { name: name, value: value }
    @attrs[name] = value
  end

  PATTERN_ATTR_KEY = /^(?<key>[a-zA-Z_]\w*)\s*(?<rest>.*)$/
  PATTERN_PARA_VARIABLE = /^(?<value>\{\{\-?\s+[a-zA-Z_][\w\.]*\s+\-?\}\})\s*(?<rest>.*)$/
  PATTERN_PARA_SINGLE_QUOTED = /^(?<value>@?'.*?')\s*(?<rest>.*)$/
  PATTERN_PARA_DOUBLE_QUOTED = /^(?<value>@?".*?")\s*(?<rest>.*)$/
  PATTERN_PARA_SIMPLE = /^(?<value>@?\S+)\s*(?<rest>.*)$/
  PATTERN_ATTR_VARIABLE = /^(?<key>[a-zA-Z_]\w*)=(?<value>\{\{\-?\s*[a-zA-Z_][\w\.]*\s+\-?\}\})\s+(?<rest>.*)$/
  PATTERN_ATTR_SINGLE_QUOTED = /^(?<key>[a-zA-Z_]\w*)=(?<value>@?'.*?')\s*(?<rest>.*)$/
  PATTERN_ATTR_DOUBLE_QUOTED = /^(?<key>[a-zA-Z_]\w*)=(?<value>@?".*?")\s*(?<rest>.*)$/
  PATTERN_ATTR_SIMPLE = /^(?<key>[a-zA-Z_]\w*)=(?<value>@?\S+)\s*(?<rest>.*)$/

  def parse!(markup)
    source = escape markup.strip
    until source.empty?
      case source
      when PATTERN_ATTR_VARIABLE
        add_attr! $~[:key].strip, $~[:value].strip
        source = $~[:rest].strip
      when PATTERN_ATTR_SINGLE_QUOTED
        add_attr! $~[:key].strip, $~[:value].strip
        source = $~[:rest].strip
      when PATTERN_ATTR_DOUBLE_QUOTED                          # TODO: проверить возможность схлопывания
        add_attr! $~[:key].strip, $~[:value].strip
        source = $~[:rest].strip
      when PATTERN_ATTR_SIMPLE
        add_attr! $~[:key].strip, $~[:value].strip
        source = $~[:rest].strip
      when PATTERN_ATTR_KEY
        add_key! $~[:key].strip
        source = $~[:rest].strip
      when PATTERN_PARA_VARIABLE
        add_param! $~[:value].strip
        source = $~[:rest].strip
      when PATTERN_PARA_SINGLE_QUOTED
        add_param! $~[:value].strip
        source = $~[:rest].strip
      when PATTERN_PARA_DOUBLE_QUOTED
        add_param! $~[:value].strip
        source = $~[:rest].strip
      when PATTERN_PARA_SIMPLE
        add_param! $~[:value].strip
        source = $~[:rest].strip
      else
        raise ArgumentError, "Invalid param(s): #{source}!"
      end
    end
    self
  end

  def [](key_or_index)
    case key_or_index
    when Integer
      @params[key_or_index]&.value
    when String
      @attrs[key_or_index.intern]
    when Symbol
      @attrs[key_or_index]
    else
      nil
    end
  end

  def each
    @params.each do |param|
      yield param
    end
  end

  def each_value
    @params.each_with_index do |param, index|
      if param[:name]
        yield param[:name], param[:value]
      else
        yield index, param[:value]
      end
    end
  end

  def each_attribute
    @attrs.each do |key, param|
      yield key, param[:value]
    end
  end

  def each_positional
    index = 0
    @params.each do |param|
      if !(param[:name])
        index += 1
        yield index, param[:value]
      end
    end
  end

  def to_h
    result = {}
    each_value do |key, value|
      result[key] = value
    end
    result
  end
end
