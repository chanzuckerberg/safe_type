require 'safe_type/rule'
require 'safe_type/errors'

require 'safe_type/primitive/boolean'
require 'safe_type/primitive/date'
require 'safe_type/primitive/date_time'
require 'safe_type/primitive/float'
require 'safe_type/primitive/integer'
require 'safe_type/primitive/string'
require 'safe_type/primitive/symbol'
require 'safe_type/primitive/time'

module SafeType
  class << self
    def coerce(input, rule, coerce_key=nil)
      return rule.coerce(input, coerce_key) if rule.is_a?(SafeType::Rule)
      if rule.class == ::Hash
        result = {}
        rule.each do |key, val|
          result[key] = coerce(input[key], val, key)
        end
        return result
      end
      if rule.class == ::Array
        return [] if input.nil?
        result = ::Array.new(input.length)
        i = 0
        while i < input.length
          result[i] = coerce(input[i], rule[i % rule.length], i)
          i += 1
        end
        return result
      end
      raise SafeType::InvalidRuleError
    end

    def coerce!(input, rule)
      if rule.class == ::Hash
        rule.each do |key, val|
          # if element is a collection, coerce individually
          if val.class == ::Hash || val.class == ::Array
            coerce!(input[key], val)
          else
            # if not a collection, reassign simple object to coerced value
            input[key] = coerce(input[key], val, key)
          end
        end
        return nil
      end
      if rule.class == ::Array
        i = 0
        while i < input.length
          val = rule[i % rule.length]
          # if this is an array of collections (Array|Hash), coerce those collections individually
          if val.class == ::Hash || val.class == ::Array
            coerce!(input[i], val)
          else
            # if not a collection, reassign simple object in array to coerced value
            input[i] = coerce(input[i], val)
          end
          i += 1
        end
        return nil
      end
      raise SafeType::InvalidRuleError
    end
  end
end
