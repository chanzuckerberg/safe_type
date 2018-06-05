# SafeType
[![Gem Version](https://badge.fury.io/rb/safe_type.svg)](https://badge.fury.io/rb/safe_type)

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

SafeType::coerce "SafeType"
```
Or `include SafeType`:
```ruby
require 'safe_type'
include SafeType

coerce "SafeType"
```

### Coerce By Default
When `SafeType::coerce` doesn't have additional argument,
  it coerces the input by default. 
***Note: Default coercion may cause unexpected behavior. 
It is safer to specify coersion rules***

1. Coerce `falsy` values to `nil`.
Following values are considered falsy:
- false
- 0
- empty strings
- NaN (or any objects respond to `nan?` and return true)
All other values which are not falsy are considered to be truthy.
```ruby
falsy? false          # => true
falsy? 0              # => true
falsy? ""             # => true
falsy? Float::NAN     # => true

coerce false          # => nil
coerce 0              # => nil
coerce ""             # => nil
coerce Float::NAN     # => nil
```
2. Coerce `String`
```ruby
coerce "123"          # => 123
coerce "123.0"        # => 123.0
coerce "2018-06-01"   # => #<Date: 2018-06-01 ((2458271j,0s,0n),+0s,2299161j)>
coerce "SafeType"     # => "SafeType"
```

### Coercion Rule
A coercion rule has to be described as a hash, with a required key `type`.
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
    which takes the value to coerce as input. 
- `validate`: A method will be called to validate the input,
    which takes the value to coerce as input. It returns `true` or `false`.
    It will empty the value to `nil` if the validation method returns `false`.

### Coerce By Rules
Coercion can by defined a set of coercion rules.
If the input is hash-like, then the rules shall be described as the values,
  for each key we want to coerce in the input. 

`coerce!` is a mutating method, which modifies the values in place.

```ruby
input = {
  name: "user",
  mail: "invalid.email.address",
  info: {
    dog_person: "true",
    num_of_dogs: "1",
    birthday: "2018-06-01",
  }
}

coerce! input, {
  name: Rule.new(type: String, required: true),
  mail: Rule.new(type: String, required: true, validate: :mail_address?),
  info: {
    dog_person: Rule.new(type: Boolean, default: true),
    num_of_dogs: Rule.new(type: Integer, default: 0),
    birthday: Rule.new(type: Date),
  }
}
```
Note mutating coercion can only be applied on a hash-like object.

```ruby
# ArgumentError: mutating coercion can only be applied on a hash-like object
coerce! "1", Rule.new(type: Integer) 
```

### Coerce Environment Variables
We have to use `String` key and values in `ENV`. 
Here is an example of type coercion on `ENV`.

```ruby
ENV["FLAG_0"] = "true"
ENV["FLAG_1"] = "false"
ENV["NUM_0"] = "123"

h = coerce ENV, {
  FLAG_0: Rule.new(type: Boolean, default: false),
  FLAG_1: Rule.new(type: Boolean, default: false),
  NUM_0: Rule.new(type: Integer),
}.stringify_keys

h["FLAG_0"]   # => true
h["FLAG_1"]   # => false
h["NUM_0"]    # => 123
```

## Prior Art
This gem was inspired by [rails_param](https://github.com/nicolasblanco/rails_param)
and [dry-types](https://github.com/dry-rb/dry-types). `dry-types` forces on setting
constrains when creating new object instances. `rails_param` replies on Rails and it is
only for the `params`. Therefore, `safe_type` was created. It integrated some ideas from both
gems, and it was designed specifically for type checking to provide an clean and easy-to-use interface.

## License
`safe_type` is released under an MIT license.
