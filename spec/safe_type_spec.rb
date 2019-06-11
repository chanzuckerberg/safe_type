require 'safe_type'

describe :SafeType do
  it "coerces flat hash" do
    require 'safe_type/mixin/hash' # stringify_keys
    input = {
      age: "15",
      happy: "true",
      percentile: "123.0",
    }.stringify_keys
    ans = {
      "age" => 15,
      "happy" => true,
      "percentile" => 123.0,
    }
    rules = {
      "age" => SafeType::Integer.strict,
      "happy" => SafeType::Boolean.strict,
      "percentile" => SafeType::Float.strict,
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
      role: SafeType::String.strict,
      info: {
        school_id: SafeType::Integer.strict,
        num_students: SafeType::Integer.strict,
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
      role: SafeType::String.strict,
      info: {
        school_id: SafeType::Integer.strict,
        num_students: SafeType::Integer.strict,
        dog_person: SafeType::Boolean.default(true),
        birthday: SafeType::Date.strict,
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
      scores: [SafeType::Float.strict],
      names: [SafeType::String.strict],
    }
    out = SafeType::coerce(input, rules)
    expect(out).to eql(ans)
    SafeType::coerce!(input, rules)
    expect(input).to eql(ans)

    input = ["1", "2", "3"]
    ans = [1, 2, 3]
    rules = [SafeType::Integer.strict]
    out = SafeType::coerce(input, rules)
    expect(out).to eql(ans)
    SafeType::coerce!(input, rules)
    expect(input).to eql(ans)

    input = ["1", "true", "3", "false"]
    ans = [1, true, 3, false]
    rules = [SafeType::Integer.strict, SafeType::Boolean.strict]
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
      false,
      [1, 2, 3],
      [1.0, 2.0, -3.0],
      [:apple, :banana],
    ]
    rules = [
      SafeType::Boolean.strict,
      [SafeType::Integer.strict],
      [SafeType::Float.strict],
      [SafeType::Symbol.strict],
    ]
    out = SafeType::coerce(input, rules)
    expect(out).to eql(ans)
    SafeType::coerce!(input, rules)
    expect(input).to eql(ans)

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
    rules = {
      "names" => [SafeType::String.strict],
      "info" => [
        {
          "type" => SafeType::String.strict,
          "age" => SafeType::Integer.strict,
          "comment" => SafeType::String.default(nil),
        }
      ]
    }
    ans = {
      "names" => ["Alice", "Bob", "Chris"],
      "info" => [
        {
          "type" => "dog",
          "age" => 5,
          "comment" => nil,
        },
        {
          "type" => "cat",
          "age" => 4,
          "comment" => nil,
        },
        {
          "type" => "fish",
          "age" => 6,
          "comment" => nil,
        }
      ]
    }
    out = SafeType::coerce(json, rules)
    expect(out).to eql(ans)
    SafeType::coerce!(json, rules)
    expect(json).to eql(ans)
  end

  it "coerce! doesn't modify unspecified fields" do
    json = {
      "multiples" => [
        ["10", "100", "1000"],
        ["20", "200", "2000"],
        ["30", "300", "3000"]
      ],
      "people" => [
        {
          "name" => "Jose",
          "favoriteNumbers" => ["2","4","6"],
          "other_info" => {
            "birth_month" => "August",
            "birth_day" => "4",
            "age" => {
              "number" => 20,
              "word" => "twenty",
            },
          }
        },
        {
          "name" => "Juan",
          "favoriteNumbers" => ["3","6","9"],
          "other_info" => {
            "birth_month" => "August",
            "birth_day" => "4",
            "age" => {
              "number" => 30,
              "word" => "thirty",
            },
          }
        },
      ]
    }
    rules = {
      "multiples" => [
        [SafeType::Integer.strict, SafeType::String.strict],
        [SafeType::Integer.strict],
        [SafeType::String.strict]
      ],
      "people" => [
        {
          "name" => SafeType::String.strict,
          "favoriteNumbers" => [SafeType::Integer.strict],
          "other_info" => {
            "birth_month" => SafeType::String.strict,
            "birth_day" => SafeType::Integer.strict,
          }
        },
      ]
    }
    ans = {
      "multiples" => [
        [10, "100", 1000],
        [20, 200, 2000],
        ["30", "300", "3000"]
      ],
      "people" => [
        {
          "name" => "Jose",
          "favoriteNumbers" => [2, 4, 6],
          "other_info" => {
            "birth_month" => "August",
            "birth_day" => 4,
            "age" => {
              "number" => 20,
              "word" => "twenty",
            },
          }
        },
        {
          "name" => "Juan",
          "favoriteNumbers" => [3, 6, 9],
          "other_info" => {
            "birth_month" => "August",
            "birth_day" => 4,
            "age" => {
              "number" => 30,
              "word" => "thirty",
            },
          }
        },
      ]
    }

    SafeType::coerce!(json, rules)
    expect(json).to eql(ans)
  end

  it "raises exceptions when coercion rules are invalid" do
    expect{
      SafeType::coerce!("true", SafeType::Rule.new(
        type: TrueClass
      ))}.to raise_error(SafeType::InvalidRuleError)

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
    }.to raise_error(SafeType::InvalidRuleError)
    expect{
      SafeType::coerce!(input, rules)
    }.to raise_error(SafeType::InvalidRuleError)
  end

  it "coerces environment varibales" do
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

    expect(SAFE_ENV[:DISABLE_TASKS]).to eql(true)
    expect(SAFE_ENV[:API_KEY]).to eql("SECRET")
    expect(SAFE_ENV[:BUILD_NUM]).to eql(123)
  end

  it "coerces to custom types" do
    class FallSemester < SafeType::Date
      def is_valid?(input)
        today = Date.today
        current_year = today.year
        if today <= Date.new(current_year, 12, 20)
          semester_start = Date.new(current_year, 8, 20)
          semester_end = Date.new(current_year, 12, 20)
        else
          semester_start = Date.new(current_year + 1, 8, 20)
          semester_end = Date.new(current_year + 1, 12, 20)
        end
        return false if input < semester_start || input > semester_end
        super
      end
    end

    current_year = Date.today.year
    expect(
      SafeType::coerce("#{current_year}-10-01", FallSemester.strict)
    ).to eql(Date.new(current_year, 10, 1))
    expect{
      SafeType::coerce(nil, FallSemester.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect{
      SafeType::coerce("#{current_year}-05-01", FallSemester.strict)
    }.to raise_error(SafeType::ValidationError)

    params = {
      "course_id" => "101",
      "start_date" => "#{current_year}-10-01"
    }
    rules = {
      "course_id" => SafeType::Integer.strict,
      "start_date" => FallSemester.strict
    }
    ans = {
      "course_id" => 101,
      "start_date" => Date.new(current_year, 10, 1)
    }
    out = SafeType::coerce(params, rules)
    expect(out).to eql(ans)
    SafeType::coerce!(params, rules)
    expect(params).to eql(ans)

    class ResponseType; end

    class Response < SafeType::Rule
      def initialize(type: ResponseType)
        super
      end

      def before(uri)
        # make request
        return ResponseType.new
      end
    end

    expect(Response.coerce("https://API_URI").is_a?(ResponseType)).to be true

    class InvalidResponse < SafeType::Rule
      def initialize(type: ResponseType, default: "404")
        super
      end

      def before(uri)
        # make request
        return nil
      end
    end

    expect(InvalidResponse.coerce("https://API_URI")).to eql("404")
  end
end
