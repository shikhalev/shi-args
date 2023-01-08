# encoding: utf-8

require_relative 'version'

require 'shi/tools'
require 'jekyll/path_manager'

module Shi::Args::Value
  class Color
    # @return [String]
    attr_reader :value

    # @return [Integer]
    attr_reader :red

    # @return [Integer]
    attr_reader :green

    # @return [Integer]
    attr_reader :blue

    # @return [Integer]
    attr_reader :alpha

    # @param source [String]
    def initialize source
      @value = source.strip
      plain = @value.slice(1..-1)
      case plain.length
      when 3
        @red = (plain.slice(0) * 2).to_i(16)
        @green = (plain.slice(1) * 2).to_i(16)
        @blue = (plain.slice(2) * 2).to_i(16)
        @alpha = nil
      when 4
        @red = (plain.slice(0) * 2).to_i(16)
        @green = (plain.slice(1) * 2).to_i(16)
        @blue = (plain.slice(2) * 2).to_i(16)
        @alpha = (plain.slice(3) * 2).to_i(16)
      when 6
        @red = plain.slice(0..1).to_i(16)
        @green = plain.slice(2..3).to_i(16)
        @blue = plain.slice(4..5).to_i(16)
        @alpha = nil
      when 8
        @red = plain.slice(0..1).to_i(16)
        @green = plain.slice(2..3).to_i(16)
        @blue = plain.slice(4..5).to_i(16)
        @alpha = plain.slice(6..7).to_i(16)
      else
        raise ArgumentError, "Invalid color: #{source}"
      end
    end

    # @return [String]
    def to_s
      @value
    end
  end

  class Measure
    class << self
      # @param number [Numeric]
      # @return [String]
      def px number
        new "#{number}px", number, :px
      end
    end

    # @return [String]
    attr_reader :value

    # @return [Numeric]
    attr_reader :number

    # @return [Symbol]
    attr_reader :unit

    # @param value [String]
    # @param number [Numeric]
    # @param unit [Symnol, String]
    def initialize value, number, unit
      @value = value
      @number = number
      @unit = unit.intern
    end

    # @return [String]
    def to_s
      @value
    end
  end

  class << self

    include Shi::Tools

    def lookup_file context, path
      site = context.registers[:site]
      relative_path = Liquid::Template.parse(path.strip).render(context)
      relative_path_with_leading_slash = Jekyll::PathManager.join('', relative_path)
      site.each_site_file do |item|
        return item if item.relative_path == relative_path
        return item if item.relative_path == relative_path_with_leading_slash
      end
      site.collections.each do |_, collection|
        collection.files.each do |file|
          return file if file.relative_path == relative_path
          return file if file.relative_path == relative_path_with_leading_slash
        end
      end
      raise ArgumentError, "Couldn't find file: #{relative_path}"
    end

    # @private
    def unquote source
      source = source.strip
      s = source.slice(0)
      f = source.slice(-1)
      if s == '"'
        if f == '"'
          return source.slice(1..-2)
        else
          raise ArgumentError, "Invalid quoted string: #{source}"
        end
      elsif s == "'"
        if f == "'"
          return source.slice(1..-2)
        else
          raise ArgumentError, "Invalid quoted string: #{source}"
        end
      else
        return source
      end
    end

    private :unquote

    UNITS = %i[
      %
      cm mm Q in pc pt px
      em ex ch rem lh rlh vw vh vmin vmax vb vi svw svh lvw lvh dvw dvh
    ]
    UNITS_PART = '(' + UNITS.map { |s| s.to_s }.join('|') + ')'

    PATTERN_TRUE = 'true'
    PATTERN_FALSE = 'false'
    PATTERN_NIL = 'nil'
    PATTERN_VARIABLE = /^\{\{\-?\s+(?<variable>[a-zA-Z_][\w\.]*)\s+\-?\}\}$/
    PATTERN_LINK = /^@(?<path>.*)$/
    PATTERN_COLOR = /^(?<color>#\h+)$/
    PATTERN_INTEGER = /^(?<number>\d+)$/
    PATTERN_FLOAT = /^(?<number>\d*\.\d+)$/
    PATTERN_INTEGER_MEASURE = Regexp.compile '^(?<number>\d+)(?<unit>' + UNITS_PART + ')$'
    PATTERN_FLOAT_MEASURE = Regexp.compile '^(?<number>\d*\.\d+)(?<unit>' + UNITS_PART + ')$'

    # @param context [Liquid::Context]
    # @param value [Sring]
    # @return [Object]
    def parse context, value
      value = value.strip
      case value
      when PATTERN_TRUE
        true
      when PATTERN_FALSE
        false
      when PATTERN_NIL
        nil
      when PATTERN_VARIABLE
        lookup context, $~[:variable]
      when PATTERN_LINK
        lookup_file context, unquote($~[:path])
      when PATTERN_COLOR
        Shi::Args::Value::Color::new $~[:color]
      when PATTERN_INTEGER
        $~[:number].to_i
      when PATTERN_FLOAT
        $~[:number].to_f
      when PATTERN_INTEGER_MEASURE
        Shi::Args::Value::Measure::new value, $~[:number].to_i, $~[:unit]
      when PATTERN_FLOAT_MEASURE
        Shi::Args::Value::Measure::new value, $~[:number].to_f, $~[:unit]
      else
        unquote value
      end
    end
  end
end
