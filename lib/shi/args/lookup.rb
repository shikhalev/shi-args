# encoding: utf-8

require_relative 'version'

class Shi::Args
  class << self
    def lookup(context, name)
      if name.nil?
        return nil
      lookup = context
      name.split(".").each do |value|
        lookup = lookup[value]
        break if lookup.nil?
      end
      lookup
    end
  end
end
