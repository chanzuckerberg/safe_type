require 'safe_type'
include SafeType

describe SafeType do
  it "considers `false` to be falsy" do
    expect(falsy? false).to be true
  end

  it "considers `0` to be falsy" do
    expect(falsy? 0).to be true
  end

  it "considers empty strings to be falsy" do
    expect(falsy? "").to be true
  end

  it "considers NaN to be falsy" do
    expect(falsy?(Float::NAN)).to be true
  end

  context "when no arguments" do
    it "converts falsy values to nil" do
      expect(coerce false).to be_nil
      expect(coerce 0).to be_nil
      expect(coerce "").to be_nil
      expect(coerce Float::NAN).to be_nil
    end

    it "coerces to true" do
      Converter.class_variable_get(:@@TRUE_VALUES).each do |input|
        expect(coerce input).to be true
      end
    end

    it "coerces to false" do
      Converter.class_variable_get(:@@FALSE_VALUES).each do |input|
        expect(coerce input).to be false
      end
    end

    it "coerces to integer" do
      expect(coerce "0").to eql(0)
      expect(coerce "91283018204810123819234141").to eql(91283018204810123819234141)
      expect(coerce "0123").to eql(123)
      expect(coerce "-123").to eql(-123)
    end

    it "coerces to float" do
      expect(coerce "0.0").to eql(0.0)
      expect(coerce "1e6").to eql(1e6)
    end
  end

  context "when coercion rules are valid" do
    it "coerces basic type" do
      expect(
        coerce "true", Rule.new(
          type: TrueClass
        )).to be true

      expect(
        coerce "false", Rule.new(
          type: FalseClass
        )).to be false

      expect(
        coerce "123", Rule.new(
          type: Float
        )).to eql(123.0)

      expect(
        coerce "2018-06-01", Rule.new(
          type: Date
        )).to eql(Date.new(2018, 6, 1))

      time = Time.now
      str = time.iso8601(9)
      expect(
        coerce str, Rule.new(
          type: Time
        )).to eql(time)

      datetime = DateTime.now
      str = datetime.iso8601(9)
      expect(
        coerce str, Rule.new(
          type: DateTime
        )).to eql(datetime)

      expect(
        coerce 123, Rule.new(
          type: String
        )).to eql("123")


      expect(
        coerce "SafeType", Rule.new(
          type: Symbol
        )).to eql(:SafeType)
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
        age: Rule.new(type: Integer),
        happy: Rule.new(type: TrueClass),
        percentile: Rule.new(type: Float),
      }
      out = coerce(input, rules)
      expect(out).to eql(ans)
      coerce!(input, rules)
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
        role: Rule.new(type: String),
        info: {
          school_id: Rule.new(type: Integer),
          num_students: Rule.new(type: Integer),
        },
      }
      out = coerce(input, rules)
      expect(out).to eql(ans)
      coerce!(input, rules)
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
        role: Rule.new(type: String),
        info: {
          school_id: Rule.new(type: Integer, required: true),
          num_students: Rule.new(type: Integer, required: true),
          dog_person: Rule.new(type: Boolean, default: true),
          birthday: Rule.new(type: Date),
        },
      }
      out = coerce(input, rules)
      expect(out).to eql(ans)
      coerce!(input, rules)
      expect(input).to eql(ans)
    end

    it "validates mail addresses" do
      expect(mail_address? "@@").to be false
      expect(mail_address? "user@@domain.com").to be false
      expect(mail_address? "user@domaincom").to be false
      expect(mail_address? "a89&*^@domain.com").to be false
      expect(mail_address? "@domain.com").to be false
      expect(mail_address? "a@domain.com").to be true

      input = {
        name: "user0",
        mail: "invalid.email.address",
      }
      ans = {
        name: "user0",
        mail: nil,
      }
      rules = {
        name: Rule.new(type: String),
        mail: Rule.new(type: String, validate: lambda {|x| mail_address? x }),
      }
      out = coerce(input, rules)
      expect(out).to eql(ans)
      coerce!(input, rules)
      expect(input).to eql(ans)
    end


    it "reserves the same types" do
      expect(coerce 1, Rule.new(type: Integer)).to eql(1)
      expect(coerce 1.0, Rule.new(type: Float)).to eql(1.0)
      expect(coerce Date.new(2018, 1, 1), Rule.new(type: Date)).to eql(Date.new(2018, 1, 1))
      expect(coerce "SafeType", Rule.new( type: String)).to eql("SafeType")
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
      r = Rule.new(type: String, before: before, after: after)
      rules = { a: r, b: r }
      out = coerce(input, rules)
      expect(out).to eql(ans)
      coerce!(input, rules)
      expect(input).to eql(ans)
    end

    it "coerces environment variables" do
      ENV["FLAG_0"] = "true"
      ENV["FLAG_1"] = "false"
      ENV["NUM_0"] = "123"

      rules = {
        FLAG_0: Rule.new(type: Boolean, default: false),
        FLAG_1: Rule.new(type: Boolean, default: false),
        NUM_0: Rule.new(type: Integer),
      }

      # ENV only accept String keys
      expect{
        coerce ENV, rules
      }.to raise_error(TypeError)

      rules = rules.stringify_keys

      h = coerce ENV, rules

      # ENV only accept String values, so we can't coerce in place
      expect{
        coerce! ENV, rules
      }.to raise_error(TypeError)

      expect(h["FLAG_0"]).to eql(true)
      expect(h["FLAG_1"]).to eql(false)
      expect(h["NUM_0"]).to eql(123)
    end
  end

  context "when coercion rules are invalid" do
    it 'raises exceptions' do
      expect{
        coerce! "true", Rule.new(
          type: TrueClass
        )}.to raise_error(ArgumentError)

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
        coerce input, rules
      }.to raise_error(ArgumentError)
      expect{
        coerce! input, rules
      }.to raise_error(ArgumentError)
    end
  end
end
