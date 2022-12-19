# encoding: utf-8

require_relative 'version'

class Shi::Args::Parameter
  attr_reader :index, :value

  def initialize(context, value)
    @context = context
    @value = value
  end

  def index
    @context.find_parameter self
  end
end

class Shi::Args::Attribute < Parameter
  attr_reader :name

  def initialize(context, name, value)
    super context, value
    @name = name.intern
  end
end

class Shi::Args::Flag < Attribute
  def initialize(context, name, value)
    super context, name, value
  end
end
