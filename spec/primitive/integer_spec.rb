require 'safe_type'

describe :coerce_integer do
  it "coerces primitive types to integer" do
    expect(
      SafeType::coerce(nil, SafeType::Integer.default(123))
    ).to eql(123)
    expect(SafeType::Integer[nil]).to eql(0)
    expect(SafeType::Integer["123"]).to eql(123)
    expect{
      SafeType::coerce(nil, SafeType::Integer.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect(
      SafeType::coerce("123", SafeType::Integer.default)
    ).to eql(123)
    expect(
      SafeType::coerce("-0123", SafeType::Integer.default)
    ).to eql(-123)
    expect(
      SafeType::coerce(123.321, SafeType::Integer.default)
    ).to eql(123)
  end

  it "coerces custom types to integer" do
    class CustomType
      def safe_type
        123
      end
    end

    expect(
      SafeType::coerce(CustomType.new, SafeType::Integer.default)
    ).to eql(123)
  end

  it "validates the input after coerce" do
    expect(
      SafeType::coerce("123", SafeType::Integer.strict(min: 3))
    ).to eql(123)
    expect{
      SafeType::coerce("123", SafeType::Integer.strict(min: 124))
    }.to raise_error(SafeType::ValidationError)
    expect{
      SafeType::coerce("123", SafeType::Integer.strict(max: 2))
    }.to raise_error(SafeType::ValidationError)
  end
end
