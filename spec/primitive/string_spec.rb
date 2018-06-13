require 'safe_type'

describe :coerce_string do
  it "coerces primitive types to string" do
    expect(
      SafeType::coerce(nil, SafeType::String.default("123"))
    ).to eql("123")
    expect{
      SafeType::coerce(nil, SafeType::String.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect(
      SafeType::coerce(123, SafeType::String.default)
    ).to eql("123")
    expect(
      SafeType::coerce(123.321, SafeType::String.default)
    ).to eql("123.321")
  end

  it "coerces custom types to string" do
    class CustomType
      def safe_type
        "has method safe_type"
      end
    end

    expect(
      SafeType::coerce(CustomType.new, SafeType::String.default)
    ).to eql("has method safe_type")
  end

  it "validates the input after coerce" do
    expect(
      SafeType::coerce(123, SafeType::String.strict(min_length: 3))
    ).to eql("123")
    expect{
      SafeType::coerce(123, SafeType::String.strict(min_length: 4))
    }.to raise_error(SafeType::ValidationError)
    expect{
      SafeType::coerce("123", SafeType::String.strict(max_length: 2))
    }.to raise_error(SafeType::ValidationError)
  end
end
