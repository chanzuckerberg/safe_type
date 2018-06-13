require 'safe_type'

describe :coerce_float do
  it "coerces primitive types to float" do
    expect(
      SafeType::coerce(nil, SafeType::Float.default(123.0))
    ).to eql(123.0)
    expect{
      SafeType::coerce(nil, SafeType::Float.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect(
      SafeType::coerce("123.321", SafeType::Float.default)
    ).to eql(123.321)
    expect(
      SafeType::coerce("-0123.321", SafeType::Float.default)
    ).to eql(-123.321)
    expect(
      SafeType::coerce(123, SafeType::Float.default)
    ).to eql(123.0)
  end

  it "coerces custom types to float" do
    class CustomType
      def safe_type
        123.321
      end
    end

    expect(
      SafeType::coerce(CustomType.new, SafeType::Float.default)
    ).to eql(123.321)
  end

  it "validates the input after coerce" do
    expect(
      SafeType::coerce("123", SafeType::Float.strict(min: 3))
    ).to eql(123.0)
    expect{
      SafeType::coerce("123", SafeType::Float.strict(min: 124))
    }.to raise_error(SafeType::ValidationError)
    expect{
      SafeType::coerce("123", SafeType::Float.strict(max: 2))
    }.to raise_error(SafeType::ValidationError)
  end
end
