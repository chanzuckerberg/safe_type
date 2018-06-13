SafeType
======
[![Gem Version](https://badge.fury.io/rb/safe_type.svg)](https://badge.fury.io/rb/safe_type)
[![Build Status](https://travis-ci.org/chanzuckerberg/safe_type.svg?branch=master)](https://travis-ci.org/chanzuckerberg/safe_type)
[![Maintainability](https://api.codeclimate.com/v1/badges/7fbc9a4038b86ef639e1/maintainability)](https://codeclimate.com/github/chanzuckerberg/safe_type/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/7fbc9a4038b86ef639e1/test_coverage)](https://codeclimate.com/github/chanzuckerberg/safe_type/test_coverage)

While working with environment variables, routing parameters, API responses,
  or other Hash-like objects require parsing,
  we often need type coercion to assure expected behaviors.

***SafeType*** provides an intuitive type coercion interface and type enhancement.

# Install

We can install `safe_type` using `gem install`: 

```bash
gem install safe_type
```

Or we can add it as a dependency in the `Gemfile` and run `bundle install`:

```ruby
gem 'safe_type'
```

# Use Cases
## Environment Variables
```ruby
require 'safe_type/mixin/hash' # symbolize_keys

ENV["DISABLE_TASKS"] = "true"
ENV["API_KEY"] = ""
ENV["BUILD_NUM"] = "123"
SAFE_ENV = SafeType::coerce(
  ENV,
  {
    "DISABLE_TASKS" => SafeType::Boolean.default(false),
    "API_KEY" => SafeType::String.default("SECRET"),
    "BUILD_NUM" => SafeType::Integer.strict,
  }
).symbolize_keys

SAFE_ENV[:DISABLE_TASKS]    # => true
SAFE_ENV[:API_KEY]          # => SECRET
SAFE_ENV[:BUILD_NUM]        # => 123
```
## Routing Parameters
```ruby
class FallSemester < SafeType::Date
  # implement validate method
end

current_year = Date.today.year
params = {
  "course_id" => "101",
  "start_date" => "#{current_year}-10-01"
}

rules = {
  "course_id" => SafeType::Integer.strict,
  "start_date" => FallSemester.strict
}

SafeType::coerce!(params, rules)

params["course_id"]       # => 101
params["start_date"]      # => <Date: 2018-10-01 ((2458393j,0s,0n),+0s,2299161j)>
```
## JSON Response
```ruby
json = {
  "names" => ["Alice", "Bob", "Chris"],
  "info" => [
    {
      "type" => "dog",
      "age" => "5",
    },
    {
      "type" => "cat",
      "age" => "4",
    },
    {
      "type" => "fish",
      "age" => "6",
    }
  ]
}

SafeType::coerce!(json, {
  "names" => [SafeType::String.strict],
  "info" => [
    {
      "type" => SafeType::String.strict,
      "age" => SafeType::Integer.strict
    }
  ]
})
```
## Http Response
```ruby
class ResponseType; end

class Response < SafeType::Rule
  def initialize(type: ResponseType, default: "404")
    super
  end

  def before(uri)
    # make request
    return ResponseType.new 
  end
end

Response["https://API_URI"]   # => #<ResponseType:0x000056005b3e7518>
```

# Overview 
A `Rule` describes a single transformation pipeline. It's the core of this gem.
```ruby
class Rule
  def initialize(type:, default: nil, required: false)
```
The parameters are
- the `type` to transform into
- the `default` value when the result is `nil`
- `required` indicates whether empty values are allowed

## `strict` vs `default`
The primitive types in *SafeType* provide `default` and `strict` mode, which are
- `SafeType::Boolean`
- `SafeType::Date`
- `SafeType::DateTime`
- `SafeType::Float`
- `SafeType::Integer`
- `SafeType::String`
- `SafeType::Symbol`
- `SafeType::Time`

Under the hood, they are all just SafeType rules.
- `default`: a rule with default value specified
- `strict`: a rule with `required: true`, so no empty values are allowed, or it throws `EmptyValueError`

## Apply the rules
As we've seen in the use cases, we can call `coerce` to apply a set of `SafeType::Rule`s.
Rules can be bundled together as elements in an array or values in a hash.

### `coerce` vs `coerce!`
- `SafeType::coerce` returns a new object, corresponding to the rules. The unspecified fields will not be included in the new object.
- `SafeType::coerce!` coerces the object in place. The unspecified fields will not be modified.
Note `SafeType::coerce!` cannot be used on a simple object, otherwise it will raise `SafeType::InvalidRuleError`. 

To apply the rule on a simple object, we can call `[]` method as well.
```ruby
SafeType::Integer.default["1"]    # => 1
SafeType::Integer["1"]            # => 1
```
For the *SafeType* primitive types, apply the rule on the class itself will use the default rule.

## Customized Types
We can inherit from a `SafeType::Rule` to create a customized type.
We can override following methods if needed:
- Override `initialize` to change the default values, types, or add more attributes.
- Override `before` to update the input before convert. This method should take the input and return it after processing.
- Override `validate` to check the value after convert. This method should take the input and return `true` or `false`.
- Override `after` to update the input after validate. This method should take the input and return it after processing.
- Override `handle_exceptions` to change the behavior of exceptions handling (e.g: send to the logger, or no exception) 
- Override `default` or `strict` to modify the default and strict rule.

# Prior Art
This gem was inspired by [rails_param](https://github.com/nicolasblanco/rails_param)
and [dry-types](https://github.com/dry-rb/dry-types). `dry-types` has a complex interface. 
Also it does not support in place coercion, and it will be complicated to `ENV` since the design of its
`Hash Schemas`. `rails_param` relies on Rails and it is only for the `params`. 
Therefore, `safe_type` was created. It integrated some ideas from both gems, 
and it was designed specifically for type checking to provide an clean and easy-to-use interface.
It should be useful when working with any string or hash where the values are coming from an external source, 
such as `ENV` variables, rails `params`, or API calls.

## License
`safe_type` is released under an MIT license.
