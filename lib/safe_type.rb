require 'date'
require 'time'

module SafeType
  module Boolean; end

  class Converter
    @@TRUE_VALUES = %w[on On ON t true True TRUE T y yes Yes YES Y].freeze
    @@FALSE_VALUES = %w[off Off OFF f false False FALSE F n no No NO N].freeze
    @@METHODS = [:to_true, :to_false, :to_int, :to_float, :to_date, :to_date_time,
      :to_time].freeze

    def self.to_true(input)
      true if @@TRUE_VALUES.include?(input.to_s)
    end

    def self.to_false(input)
      false if @@FALSE_VALUES.include?(input.to_s)
    end

    def self.to_bool(input)
      return true unless self.to_true(input).nil?
      return false unless self.to_false(input).nil?
    end

    def self.to_int(input)
      Integer(input, base=10)
    end

    def self.to_float(input)
      Float(input)
    end

    def self.to_date(input)
      return input unless input.respond_to?(:to_str)
      Date.parse(input)
    rescue ArgumentError, RangeError
      input
    end

    def self.to_date_time(input)
      return input unless input.respond_to?(:to_str)
      DateTime.parse(input)
    rescue ArgumentError
      input
    end

    def self.to_time(input)
      return input unless input.respond_to?(:to_str)
      Time.parse(input)
    rescue ArgumentError
      input
    end

    def self.to_type(input, type)
      return input if input.is_a?(type)
      return input.to_s if type == String
      return input.to_sym if type == Symbol
      return self.to_true(input) if type == TrueClass
      return self.to_false(input) if type == FalseClass
      return self.to_bool(input) if type == Boolean
      return self.to_int(input) if type == Integer
      return self.to_float(input) if type == Float
      return self.to_date(input) if type == Date
      return self.to_date_time(input) if type == DateTime
      return self.to_time(input) if type == Time
      return type.try_convert(input) if type.respond_to?(:try_convert)
      return type.new(input) if type.respond_to?(:new)
    end
  end

  class Rule
    attr_reader :type, :default, :before, :after, :validate
    def initialize(r)
      raise ArgumentError, "SafeType::Rule has to be descried as a hash" \
        unless r.class == ::Hash
      raise ArgumentError, ":type key is required" \
        unless r.has_key?(:type)
      raise ArgumentError, ":type has to a class or module" \
        unless r[:type].class == ::Class || r[:type].class == ::Module
      @type = r[:type]
      @required = false
      @required = true if r.has_key?(:required) && r[:required]
      @has_default = r.has_key?(:default)
      @default = r[:default]
      @before = r[:before]
      @after = r[:after]
      @validate = r[:validate]
    end

    def required?; @required; end

    def has_default?; @has_default; end

    def apply(input)
      input = @before[input] unless @before.nil?
      begin
        result = Converter.to_type(input, @type) \
          if @validate.nil? || (!@validate.nil? && @validate[input])
      rescue ArgumentError, TypeError
        return @default if @has_default
        return nil unless @required
      end
      raise TypeError, "invalid conversion" if result.nil? && @required
      return @default if result.nil?
      return @after[result] unless @after.nil?
      result
    end
  end

  def falsy?(input)
    return true if input == false
    return true if input == 0
    return true if input == ""
    return true if input.respond_to?(:nan?) && input.nan?
    false
  end

  def truthy?(input)
    !falsy?(input)
  end

  def mail_address?(input)
    !/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.match(input).nil?
  end

  def coerce(input, params=nil)
    if params.nil?
      return nil if falsy?(input)
      Converter.class_variable_get(:@@METHODS).each do |m|
        begin
          result = Converter.method(m).call(input)
        rescue ArgumentError, TypeError
          result = nil
        end
        return result unless result.nil?
      end
      return input
    end
    return params.apply(input) if params.class == Rule
    if params.class == ::Hash
      result = {}
      params.each do |key, val|
        result[key] = coerce input[key], val
      end
      return result
    end
    raise ArgumentError, "invalid coercion rule"
  end

  def coerce!(input, params)
    raise ArgumentError, "mutating coercion can only be applied on a hash-like object" \
      unless params.class == ::Hash
    params.each do |key, val|
      if val.class == ::Hash
        coerce! input[key], val
      else
        input[key] = coerce input[key], val
      end
    end
  end

  class << self
    include SafeType
  end
end

class TrueClass; include SafeType::Boolean; end
class FalseClass; include SafeType::Boolean; end

class Hash
  def stringify_keys
    Hash[self.map{ |key, val| [key.to_s, val] }]
  end
  def symbolize_keys
    Hash[self.map{ |key, val| [key.to_sym, val] }]
  end
end
