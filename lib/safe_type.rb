require 'date'
require 'time'

module SafeType
  module Boolean; end

  module HashHelper
    def stringify_keys
      Hash[self.map{ |key, val| [key.to_s, val] }]
    end
    def symbolize_keys
      Hash[self.map{ |key, val| [key.to_sym, val] }]
    end
  end

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
    end

    def self.to_date_time(input)
      return input unless input.respond_to?(:to_str)
      DateTime.parse(input)
    end

    def self.to_time(input)
      return input unless input.respond_to?(:to_str)
      Time.parse(input)
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

  class CoercionError < TypeError
    def initialize(msg="unable to transform the input into the requested type.")
      super
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
      rescue
        return @default if @has_default
        return nil unless @required
      end
      result = @after[result] unless @after.nil?
      raise CoercionError if result.nil? && @required
      return @default if result.nil?
      result
    end
  end

  module Default
    def self.String(val, validate: nil, before: nil, after: nil)
      Rule.new(type: String, default: val, validate: validate, before: before, after: after)
    end

    def self.Symbol(val, validate: nil, before: nil, after: nil)
      Rule.new(type: Symbol, default: val, validate: validate, before: before, after: after)
    end

    def self.Boolean(val, validate: nil, before: nil, after: nil)
      Rule.new(type: Boolean, default: val, validate: validate, before: before, after: after)
    end

    def self.Integer(val, validate: nil, before: nil, after: nil)
      Rule.new(type: Integer, default: val, validate: validate, before: before, after: after)
    end

    def self.Float(val, validate: nil, before: nil, after: nil)
      Rule.new(type: Float, default: val, validate: validate, before: before, after: after)
    end

    def self.Date(val, validate: nil, before: nil, after: nil)
      Rule.new(type: Date, default: val, validate: validate, before: before, after: after)
    end

    def self.DateTime(val, validate: nil, before: nil, after: nil)
      Rule.new(type: DateTime, default: val, validate: validate, before: before, after: after)
    end

    def self.Time(val, validate: nil, before: nil, after: nil)
      Rule.new(type: Time, default: val, validate: validate, before: before, after: after)
    end
  end

  module Required
    def self.String(validate: nil, before: nil, after: nil)
      Rule.new(type: ::String, required: true, validate: validate, before: before, after: after)
    end

    def self.Symbol(validate: nil, before: nil, after: nil)
      Rule.new(type: ::Symbol, required: true, validate: validate, before: before, after: after)
    end

    def self.Boolean(validate: nil, before: nil, after: nil)
      Rule.new(type: SafeType::Boolean, required: true, validate: validate,
               before: before, after: after)
    end

    def self.Integer(validate: nil, before: nil, after: nil)
      Rule.new(type: ::Integer, required: true, validate: validate, before: before, after: after)
    end

    def self.Float(validate: nil, before: nil, after: nil)
      Rule.new(type: ::Float, required: true, validate: validate, before: before, after: after)
    end

    def self.Date(validate: nil, before: nil, after: nil)
      Rule.new(type: ::Date, required: true, validate: validate, before: before, after: after)
    end

    def self.DateTime(validate: nil, before: nil, after: nil)
      Rule.new(type: ::DateTime, required: true, validate: validate, before: before, after: after)
    end

    def self.Time(validate: nil, before: nil, after: nil)
      Rule.new(type: ::Time, required: true, validate: validate, before: before, after: after)
    end

    String = Rule.new(type: ::String, required: true)
    Symbol = Rule.new(type: ::Symbol, required: true)
    Boolean = Rule.new(type: SafeType::Boolean, required: true)
    Integer = Rule.new(type: ::Integer, required: true)
    Float = Rule.new(type: ::Float, required: true)
    Date = Rule.new(type: ::Date, required: true)
    DateTime = Rule.new(type: ::DateTime, required: true)
    Time = Rule.new(type: ::Time, required: true)
  end

  def coerce(input, params)
    return params.apply(input) if params.class == Rule
    if params.class == ::Hash
      result = {}
      params.each do |key, val|
        result[key] = coerce(input[key], val)
      end
      return result
    end
    if params.class == ::Array
      return [] if input.nil?
      result = Array.new(input.length)
      i = 0
      while i < input.length
        result[i] = coerce(input[i], params[i % params.length])
        i += 1
      end
      return result
    end
    raise ArgumentError, "invalid coercion rule"
  end

  def coerce!(input, params)
    if params.class == ::Hash
      params.each do |key, val|
        if val.class == ::Hash
          coerce!(input[key], val)
        else
          input[key] = coerce(input[key], val)
        end
      end
      return nil
    end
    if params.class == ::Array
      i = 0
      while i < input.length
        input[i] = coerce(input[i], params[i % params.length])
        i += 1
      end
      return nil
    end
    raise ArgumentError, "invalid coercion rule"
  end

  class << self
    include SafeType
  end
end

class TrueClass; include SafeType::Boolean; end
class FalseClass; include SafeType::Boolean; end
class Hash; include SafeType::HashHelper; end
