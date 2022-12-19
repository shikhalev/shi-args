# encoding: utf-8

require_relative 'version'
require_relative 'values'
require_relative 'parameters'

class Shi::Args::ContextError < RuntimeError; end

class Shi::Args
  class << self
    def parse(args)
      ctx = Context.new
      ctx.parse! args
    end
  end

  UNITS = %i[
    %
    cm mm Q in pc pt px
    em ex ch rem lh rlh vw vh vmin vmax vb vi svw svh lvw lvh dvw dvh
  ]
  UNITS_PART = UNITS.map { |s| s.to_s }.join("|")

  PATTERN_PARA_VARIABLE = /^(?<variable>\{\{\-?\s?([[:alpha:]]|_)[\w\.]*\s?\-?\}\})(?<rest>$|\s+.*)/
  PATTERN_FLAG = /^(?<key>([[:alpha:]]|_)[\w]*)(?<rest>$|\s+.*)/
  PATTERN_PATH = /^(?<path>[\w\.\-\/]+)(?<rest>$|\s+.*)/
  PATTERN_PARA_SINGLE_QUOTED = /^(?<quoted>'.*?')(?<rest>$|\s.*)/
  PATTERN_PARA_DOUBLE_QUOTED = /^(?<quoted>".*?")(?<rest>$|\s.*)/
  PATTERN_ATTR_KEYWORD = /^(?<key>([[:alpha:]]|_)\w*)=(?<keyword>true|false|nil)(?<rest>$|\s.*)/
  PATTERN_ATTR_VARIABLE = /^(?<key>([[:alpha:]]|_)\w*)=(?<variable>([[:alpha:]]|_)[\w\.]*)(?<rest>$|\s.*)/
  PATTERN_ATTR_INTEGER = /^(?<key>([[:alpha:]]|_)\w*)=(?<integer>\d+)(?<rest>$|\s.*)/
  PATTERN_ATTR_HEX = /^(?<key>([[:alpha:]]|_)\w*)=(?<hexa>#\h+)(?<rest>$|\s.*)/
  PATTERN_ATTR_FLOAT = /^(?<key>([[:alpha:]]|_)\w*)=(?<float>\d?\.\d+)(?<rest>$|\s.*)/
  PATTERN_ATTR_INTEGER_U = Regexp.compile('^(?<key>([[:alpha:]]|_)\w*)=(?<integer>\d+(' + UNITS_PART + '))(?<rest>$|\s.*)')
  PATTERN_ATTR_FLOAT_U = Regexp.compile('^(?<key>([[:alpha:]]|_)\w*)=(?<float>\d?\.\d+(' + UNITS_PART + '))(?<rest>$|\s.*)')
  PATTERN_ATTR_SINGLE_QUOTED = /^(?<key>([[:alpha:]]|_)\w*)=(?<quoted>'.*?')(?<rest>$|\s.*)/
  PATTERN_ATTR_DOUBLE_QUOTED = /^(?<key>([[:alpha:]]|_)\w*)=(?<quoted>".*?")(?<rest>$|\s.*)/

  attr_reader :parameters, :attributes

  def initialize
    @parameters = []
    @attributes = {}
  end

  def [](kix)
    case kix
    when Integer
      @parameters[kix]&.value&.value
    when String
      @attributes[kix.intern]&.value&.value
    when Symbol
      @attributes[kix]&.value&.value
    end
  end

  def new_parameter_variable(source)
    @parameters << Parameter::new(self, Value::Variable::new(source))
  end

  def new_parameter_path(source)
    @parameters << Parameter::new(self, Value::Path::new(source))
  end

  def new_parameter_quoted(source)
    @parameters << Parameter::new(self, Value::Quoted::new(source))
  end

  def new_flag(name)
    name = name.intern
    para = Attribute::new(self, name, Value::Flag::new)
    @parameters << para
    @attributes[name] = para
  end

  def new_attribute_variable(name, source)
    name = name.intern
    para = Attribute::new(self, name, Value::Variable::new(source))
    @parameters << para
    @attributes[name] = para
  end

  def new_attribute_keyword(name, source)
    name = name.intern
    value = case source
      when "false"
        false
      when "true"
        true
      when "nil"
        nil
      end
    value_object = if value == nil
        Value::Nil::new
      else
        Value::Boolean::new(source, value)
      end
    para = Attribute::new(name, value_object)
    @parameters << para
    @attributes[name] = para
  end

  def new_attribute_quoted(name, source)
    name = name.intern
    para = Attribute::new(self, name, Value::Quoted::new(source))
    @parameters << para
    @attributes[name] = para
  end

  def new_attribute_integer(name, source)
    name = name.intern
    para = Attribute::new(self, name, Value::Integer::new(source))
    @parameters << para
    @attributes[name] = para
  end

  def new_attribute_float(name, source)
    name = name.intern
    para = Attribute::new(self, name, Value::Float::new(source))
    @parameters << para
    @attributes[name] = para
  end

  def new_attribute_hex(name, source)
    name = name.intern
    para = Attribute::new(self, name, Value::Hex::new(source))
    @parameters << para
    @attributes[name] = para
  end

  def new_attribute_integer_with_unit(name, source)
    name = name.intern
    para = Attribute::new(self, name, Value::WithUnit::Integer::new(source))
    @parameters << para
    @attributes[name] = para
  end

  def new_attribute_float_with_unit(name, source)
    name = name.intern
    para = Attribute::new(self, name, Value::WithUnit::Float::new(source))
    @parameters << para
    @attributes[name] = para
  end

  private :new_parameter_variable, :new_parameter_path, :new_parameter_quoted,
    :new_flag, :new_attribute_variable, :new_attribute_keyword, :new_attribute_quoted, :new_attribute_integer, :new_attribute_float,
    :new_attribute_hex, :new_attribute_integer_with_unit, :new_attribute_float_with_unit

  def parse!(args)
    args = args.strip
    if !args.empty?
      case args
      when PATTERN_PARA_VARIABLE
        new_parameter_variable $~[:variable].strip
        parse! $~[:rest]
      when PATTERN_FLAG
        new_flag $~[:key].strip
        parse! $~[:rest]
      when PATTERN_PATH
        new_parameter_path $~[:path].strip
        parse! $~[:rest]
      when PATTERN_PARA_SINGLE_QUOTED
        new_parameter_quoted $~[:quoted].strip
        parse! $~[:rest]
      when PATTERN_PARA_DOUBLE_QUOTED
        new_parameter_quoted $~[:quoted].strip
        parse! $~[:rest]
      when PATTERN_ATTR_KEYWORD
        new_attribute_keyword $~[:key].strip, $~[:keyword].strip
        parse! $~[:rest]
      when PATTERN_ATTR_VARIABLE
        new_attribute_variable $~[:key].strip, $~[:variable].strip
        parse! $~[:rest]
      when PATTERN_ATTR_INTEGER
        new_attribute_integer $~[:key].strip, $~[:integer].strip
        parse! $~[:rest]
      when PATTERN_ATTR_HEX
        new_attribute_hex $~[:key].strip, $~[:hexa].strip
        parse! $~[:rest]
      when PATTERN_ATTR_FLOAT
        new_attribute_float $~[:kye].strip, $~[:float].strip
        parse! $~[:rest]
      when PATTERN_ATTR_INTEGER_U
        new_attribute_integer_with_unit $~[:key].strip, $~[:integer].strip
        parse! $~[:rest]
      when PATTERN_ATTR_FLOAT_U
        new_attribute_float_with_unit $~[:key].strip, $~[:float].strip
        parse! $~[:rest]
      when PATTERN_ATTR_SINGLE_QUOTED
        new_attribute_quoted $~[:key].strip, $~[:quoted].strip
        parse! $~[:rest]
      when PATTERN_ATTR_DOUBLE_QUOTED
        new_attribute_quoted $~[:key].strip, $~[:quoted].strip
        parse! $~[:rest]
      else
        raise ArgumentError.new "Invalid arguments from: #{src}"
      end
    end
    self
  end

  def attach!(render_context)
    @render_context = render_context
    @parameters.each do |param|
      val = param.value
      if Value::Variable === val
        val.attach! @render_context
      end
    end
  end

  def find_parameter(obj)
    @parameters.find_index obj
  end

  def to_hash
    result = {}
    @parameters.each_with_index do |param, index|
      if Attribute === param
        result[param.name] = param.value.source
      else
        result[index] = param.value.source
      end
    end
    result
  end

  def each
    @parameters.each do |param|
      yield param
    end
  end

  def each_parameter
    @parameters.each do |param|
      yield param unless Attribute === param
    end
  end

  def each_attribute
    @attributes.each do |key, param|
      yield key, param
    end
  end
end
