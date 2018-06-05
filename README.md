# SafeType
[![Gem Version](https://badge.fury.io/rb/safe_type.svg)](https://badge.fury.io/rb/safe_type)
[![Build Status](https://travis-ci.org/chanzuckerberg/safe_type.svg?branch=master)](https://travis-ci.org/chanzuckerberg/safe_type)
[![Maintainability](https://api.codeclimate.com/v1/badges/7fbc9a4038b86ef639e1/maintainability)](https://codeclimate.com/github/chanzuckerberg/safe_type/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/7fbc9a4038b86ef639e1/test_coverage)](https://codeclimate.com/github/chanzuckerberg/safe_type/test_coverage)

While working with environment variables, routing parameters, JSON objects,
  or other Hash-like objects require parsing,
  we often require type coercion to assure expected behaviors.

***SafeType*** provides an intuitive type coercion interface and type enhancement.

## Install

We can install `safe_type` using `gem install`: 

```bash
gem install safe_type
```

Or we can add it as a dependency in the `Gemfile` and run `bundle install`:

```ruby
gem 'safe_type'
```

## Usage
Using `SafeType` namespace:
```ruby
require 'safe_type'

SafeType::coerce("SafeType", SafeType::Required::String)
```

### Coercion with Default Value
```ruby
SafeType::coerce("true", SafeType::Default::Boolean(false))   # => true
SafeType::coerce(nil, SafeType::Default::Boolean(false))      # => false
SafeType::coerce("a", SafeType::Default::Symbol(:a))          # => :a
SafeType::coerce("123", SafeType::Default::Integer(nil))      # => 123
SafeType::coerce("1.0", SafeType::Default::Float(nil))        # => 1.0
SafeType::coerce("2018-06-01", SafeType::Default::Date(nil))
# => #<Date: 2018-06-01 ((2458271j,0s,0n),+0s,2299161j)>
```
### Coercion with Required Value
```ruby
SafeType::coerce("true", SafeType::Required::Boolean)         # => true
SafeType::coerce(nil, SafeType::Required::Boolean)            # => SafeType::CoercionError 
SafeType::coerce("123!", SafeType::Required::Integer)         # => SafeType::CoercionError
```

### Coercion Rule
Under the hood, all `SafeType::Required` and `SafeType::Default` modules are just
methods for creating coercion rules. A coercion rule has to be described as a hash, 
with a required key `type`.
```ruby
r = Rule.new(type: Integer)
```
A coercion rules support other parameters such as:
- `required`: If a value is `nil` and has a rule with `required`,
    it will raise an exception.
- `default`: If a value is `nil` (not present or failed to convert),
    it will be filled with the default.
- `before`: A method will be called before the coercion,
    which takes the value to coerce as input.
- `after`: A method will be called after the coercion,
    which takes the coercion result as input. 
- `validate`: A method will be called to validate the input,
    which takes the value to coerce as input. It returns `true` or `false`.
    It will empty the value to `nil` if the validation method returns `false`.

### Coerce By Rules
Coercion can by defined a set of coercion rules.
If the input is hash-like, then the rules shall be described as the values,
  for each key we want to coerce in the input. 

`coerce!` is a mutating method, which modifies the values in place.

```ruby
RequiredRecentDate = SafeType::Rule.new(
  type: Date, required: true, after: lambda { |date|
    date if date >= Date.new(2000, 1, 1) && date <= Date.new(2020, 1, 1)
  })

# => <Date: 2015-01-01 ((2457024j,0s,0n),+0s,2299161j)> 
SafeType::coerce("2015-01-01", RequiredRecentDate) 
# SafeType::CoercionError
SafeType::coerce("3000-01-01", RequiredRecentDate)
```
Note mutating coercion can only be applied on a hash-like object.

```ruby
# ArgumentError: mutating coercion can only be applied on a hash-like object
SafeType::coerce!("1", Rule.new(type: Integer))
```

### Coerce Environment Variables
We have to use `String` key and values in `ENV`. 
Here is an example of type coercion on `ENV`.

```ruby
ENV["FLAG_0"] = "true"
ENV["FLAG_1"] = "false"
ENV["NUM_0"] = "123"

h = SafeType::coerce(ENV, {
  FLAG_0: SafeType::Default::Boolean(false),
  FLAG_1: SafeType::Default::Boolean(false),
  NUM_0: SafeType::Default::Integer(0),
}.stringify_keys).symbolize_keys 

h[:FLAG_0]   # => true
h[:FLAG_1]   # => false
h[:NUM_0]    # => 123
```

### Coerce Hash-like Objects
```ruby
params = {
  scores: ["5.0", "3.5", "4.0", "2.2"],
  names: ["a", "b", "c", "d"],
}

SafeType::coerce!(params, {
  scores: [SafeType::Required::Float],
  names: [SafeType::Required::String],
})

params[:scores]   # => [5.0, 3.5, 4.0, 2.2]
params[:names]    # => ["a", "b", "c", "d"]
```

## Prior Art
This gem was inspired by [rails_param](https://github.com/nicolasblanco/rails_param)
and [dry-types](https://github.com/dry-rb/dry-types). `dry-types` forces on setting
constrains when creating new object instances. `rails_param` replies on Rails and it is
only for the `params`. Therefore, `safe_type` was created. It integrated some ideas from both
gems, and it was designed specifically for type checking to provide an clean and easy-to-use interface.

## License
`safe_type` is released under an MIT license.
