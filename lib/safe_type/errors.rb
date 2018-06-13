module SafeType
  class Error < StandardError; end

  class CoercionError < Error
    def initialize(message="unable to transform into the requested type")
      super
    end
  end

  class ValidationError < Error
    def initialize(message="failed to validate")
      super
    end
  end

  class EmptyValueError < Error
    def initialize(message="the value should not be empty")
      super
    end
  end

  class InvalidRuleError < ArgumentError
    def initialize(message="invalid coercion rule")
      super
    end
  end
end
