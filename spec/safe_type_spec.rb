require 'safe_type'

class MyDate < Date
  def self.try_convert(input)
    Date.parse(input)
  rescue
    Date.new(2018, 1, 1)
  end
end

class MyObject
  attr_reader :num
  def initialize(input)
    @num = input.to_i * 2
  end
end

describe SafeType do
  context "when coercion rules are valid" do
    it "coerces basic type with default value" do
      expect(SafeType::coerce(
        "true", SafeType::Default::Boolean(false)
      )).to be true
      expect(SafeType::coerce(
        nil, SafeType::Default::Boolean(false)
      )).to be false
      expect(SafeType::coerce(
        "a", SafeType::Default::Symbol(:a)
      )).to eql(:a)
      expect(SafeType::coerce(
        "123", SafeType::Default::Integer(nil)
      )).to eql(123)
      expect(SafeType::coerce(
        "123", SafeType::Default::Float(nil)
      )).to eql(123.0)
      expect(SafeType::coerce(
        "2018-06-01", SafeType::Default::Date(nil)
      )).to eql(Date.new(2018, 6, 1))

      time = Time.now
      str = time.iso8601(9)
      expect(SafeType::coerce(
        str, SafeType::Default::Time(nil)
      )).to eql(time)

      datetime = DateTime.now
      str = datetime.iso8601(9)
      expect(SafeType::coerce(
        str, SafeType::Default::DateTime(nil)
      )).to eql(datetime)

      expect(SafeType::coerce(
        123, SafeType::Default::String(nil)
      )).to eql("123")
    end

    it "coerces basic type without default value" do
      expect(SafeType::coerce(
        "true", SafeType::Required::Boolean()
      )).to be true
      expect{SafeType::coerce(
        nil, SafeType::Required::Boolean
      )}.to raise_error(SafeType::CoercionError)
      expect(SafeType::coerce(
        "a", SafeType::Required::Symbol
      )).to eql(:a)
      expect{SafeType::coerce(
        [], SafeType::Required::Symbol
      )}.to raise_error(SafeType::CoercionError)
      expect(SafeType::coerce(
        "123", SafeType::Required::Integer
      )).to eql(123)
      expect{SafeType::coerce(
        "123!", SafeType::Required::Integer
      )}.to raise_error(SafeType::CoercionError)
      expect(SafeType::coerce(
        "123", SafeType::Required::Float()
      )).to eql(123.0)
      expect{SafeType::coerce(
        "123..", SafeType::Required::Float
      )}.to raise_error(SafeType::CoercionError)
      expect(SafeType::coerce(
        "2018-06-01", SafeType::Required::Date()
      )).to eql(Date.new(2018, 6, 1))
      expect{SafeType::coerce(
        "apple", SafeType::Required::Date
      )}.to raise_error(SafeType::CoercionError)

      time = Time.now
      str = time.iso8601(9)
      expect(SafeType::coerce(
        str, SafeType::Required::Time()
      )).to eql(time)
      expect{SafeType::coerce(
        "apple", SafeType::Required::Time
      )}.to raise_error(SafeType::CoercionError)

      datetime = DateTime.now
      str = datetime.iso8601(9)
      expect(SafeType::coerce(
        str, SafeType::Required::DateTime()
      )).to eql(datetime)
      expect{SafeType::coerce(
        "apple", SafeType::Required::DateTime
      )}.to raise_error(SafeType::CoercionError)

      expect(SafeType::coerce(
        123, SafeType::Required::String
      )).to eql("123")
    end

    it "coerces flat hash" do
      input = {
        age: "15",
        happy: "true",
        percentile: "123.0",
      }
      ans = {
        age: 15,
        happy: true,
        percentile: 123.0,
      }
      rules = {
        age: SafeType::Required::Integer(),
        happy: SafeType::Default::Boolean(false),
        percentile: SafeType::Required::Float,
      }
      out = SafeType::coerce(input, rules)
      expect(out).to eql(ans)
      SafeType::coerce!(input, rules)
      expect(input).to eql(ans)
    end

    it "coerces nested hash" do
      input = {
        role: "teacher",
        info: {
          school_id: "1",
          num_students: "100",
        },
      }
      ans = {
        role: "teacher",
        info: {
          school_id: 1,
          num_students: 100,
        },
      }
      rules = {
        role: SafeType::Required::String(
          validate: lambda { |x|
            x == "teacher" || x == "student"
          }),
        info: {
          school_id: SafeType::Required::Integer,
          num_students: SafeType::Required::Integer,
        },
      }
      out = SafeType::coerce(input, rules)
      expect(out).to eql(ans)
      SafeType::coerce!(input, rules)
      expect(input).to eql(ans)

      input = {
        role: "teacher",
        info: {
          school_id: "1",
          num_students: "100",
          birthday: "2018-06-01",
        },
      }
      ans = {
        role: "teacher",
        info: {
          school_id: 1,
          num_students: 100,
          dog_person: true,
          birthday: Date.new(2018, 6, 1),
        },
      }
      rules = {
        role: SafeType::Required::String,
        info: {
          school_id: SafeType::Required::Integer,
          num_students: SafeType::Required::Integer,
          dog_person: SafeType::Default::Boolean(true),
          birthday: SafeType::Required::Date,
        },
      }
      out = SafeType::coerce(input, rules)
      expect(out).to eql(ans)
      SafeType::coerce!(input, rules)
      expect(input).to eql(ans)
    end

    it "coerces flat array" do
      input = {
        scores: ["5.0", "3.5", "4.0", "2.2"],
        names: ["a", "b", "c", "d"],
      }
      ans = {
        scores: [5.0, 3.5, 4.0, 2.2],
        names: ["a", "b", "c", "d"],
      }
      rules = {
        scores: [SafeType::Required::Float],
        names: [SafeType::Required::String],
      }
      out = SafeType::coerce(input, rules)
      expect(out).to eql(ans)
      SafeType::coerce!(input, rules)
      expect(input).to eql(ans)

      input = ["1", "2", "3"]
      ans = [1, 2, 3]
      rules = [SafeType::Required::Integer]
      out = SafeType::coerce(input, rules)
      expect(out).to eql(ans)
      SafeType::coerce!(input, rules)
      expect(input).to eql(ans)

      input = ["1", "true", "3", "false"]
      ans = [1, true, 3, false]
      rules = [SafeType::Required::Integer, SafeType::Required::Boolean]
      out = SafeType::coerce(input, rules)
      expect(out).to eql(ans)
      SafeType::coerce!(input, rules)
      expect(input).to eql(ans)
    end

    it "coerces nested array" do
      input = [
        false,
        ["1", "2", "3"],
        ["1.0", "2.0", "-3.0"],
        ["apple", "banana"],
      ]
      ans = [
        true,
        [1, 2, 3],
        [1.0, 2.0, -3.0],
        [:apple, :banana],
      ]
      rules = [
        SafeType::Required::Boolean(after: lambda { |x| !x }),
        [SafeType::Required::Integer],
        [SafeType::Required::Float],
        [SafeType::Required::Symbol(validate: lambda { |x|
          x.length <= 15
        })],
      ]
      out = SafeType::coerce(input, rules)
      expect(out).to eql(ans)
      SafeType::coerce!(input, rules)
      expect(input).to eql(ans)
    end

    it "reserves the same types" do
      expect(SafeType::coerce(
        1, SafeType::Rule.new(type: Integer))).to eql(1)
      expect(SafeType::coerce(
        1.0, SafeType::Rule.new(type: Float))).to eql(1.0)
      expect(SafeType::coerce(
        Date.new(2018, 1, 1), SafeType::Rule.new(type: Date))).to eql(Date.new(2018, 1, 1))
      expect(SafeType::coerce(
        "SafeType", SafeType::Rule.new( type: String))).to eql("SafeType")
    end

    it "applies method before and after coercion" do
      before = lambda { |x| x * 2 }
      after = lambda { |x| x.reverse }
      input = {
        a: 100,
        b: 112,
      }
      ans = {
        a: "002",
        b: "422",
      }
      r = SafeType::Rule.new(type: String, before: before, after: after)
      rules = { a: r, b: r }
      out = SafeType::coerce(input, rules)
      expect(out).to eql(ans)
      SafeType::coerce!(input, rules)
      expect(input).to eql(ans)
    end

    it "coerces environment variables" do
      ENV["FLAG_0"] = "true"
      ENV["FLAG_1"] = "false"
      ENV["NUM_0"] = "123"

      rules = {
        FLAG_0: SafeType::Default::Boolean(false),
        FLAG_1: SafeType::Default::Boolean(false),
        NUM_0: SafeType::Default::Integer(0),
      }

      # ENV only accept String keys
      expect{
        SafeType::coerce(ENV, rules)
      }.to raise_error(TypeError)

      rules = rules.stringify_keys

      h = SafeType::coerce(ENV, rules)

      # ENV only accept String values, so we can't coerce in place
      expect{
        SafeType::coerce!(ENV, rules)
      }.to raise_error(TypeError)

      h = h.symbolize_keys

      expect(h[:FLAG_0]).to eql(true)
      expect(h[:FLAG_1]).to eql(false)
      expect(h[:NUM_0]).to eql(123)
    end
  end

  context "when coercion rules are invalid" do
    it "raises exceptions" do
      expect{
        SafeType::coerce!("true", SafeType::Rule.new(
          type: TrueClass
        ))}.to raise_error(ArgumentError)

      input = {
        age: "15",
        happy: "true",
        percentile: "123.0",
      }
      ans = {
        age: 15,
        happy: true,
        percentile: 123.0,
      }
      rules = {
        age: Integer,
        happy: TrueClass,
        percentile: Float,
      }
      expect{
        SafeType::coerce(input, rules)
      }.to raise_error(ArgumentError)
      expect{
        SafeType::coerce!(input, rules)
      }.to raise_error(ArgumentError)
    end
  end

  it "coerces custom types" do
    expect(SafeType::coerce(
      "apple", SafeType::Rule.new(type: MyDate)
    )).to eql(Date.new(2018, 1, 1))

    expect(SafeType::coerce(
      "1", SafeType::Rule.new(type: MyObject)
    ).num).to eql(2)

    RequiredRecentDate = SafeType::Rule.new(
      type: Date, required: true, after: lambda { |date|
        date if date >= Date.new(2000, 1, 1) && date <= Date.new(2020, 1, 1)
      })

    expect(SafeType::coerce("2015-01-01", RequiredRecentDate)).to eql(Date.new(2015, 1, 1))
    expect{SafeType::coerce(
      "3000-01-01", RequiredRecentDate)}.to raise_error(SafeType::CoercionError)
  end
end
