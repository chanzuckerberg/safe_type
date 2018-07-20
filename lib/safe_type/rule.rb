require 'safe_type/converter'
require 'safe_type/errors'

module SafeType
  class Rule
    def initialize(type:, default: nil, required: false, **args)
      unless type.class == ::Class || type.class == ::Module
        raise ArgumentError.new("type has to a class or module")
      end
      @type = type
      @required = required
      @default = default
    end

    def is_valid?(input)
      true
    end

    def before(input)
      input
    end

    def after(input)
      input
    end

    def handle_exceptions(e)
      raise SafeType::CoercionError
    end

    def self.coerce(input)
      default.coerce(input)
    end

    def self.default
      new
    end

    def self.strict
      new(required: true)
    end

    def coerce(input)
      raise SafeType::EmptyValueError if input.nil? && @required
      input = before(input)
      input = Converter.to_type(input, @type)
      raise SafeType::ValidationError unless is_valid?(input)
      result = after(input)
      raise SafeType::EmptyValueError if result.nil? && @required
      return @default if result.nil?
      raise SafeType::CoercionError unless result.is_a?(@type)
      result
    rescue TypeError, ArgumentError, NoMethodError => e
      return @default if input.nil? && !@required
      handle_exceptions(e)
    end
  end
end
