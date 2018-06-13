require 'safe_type'

describe :coerce_symbol do
  it "coerces primitive types to symbol" do
    expect(
      SafeType::coerce(nil, SafeType::Symbol.default(:abc))
    ).to eql(:abc)
    expect{
      SafeType::coerce(nil, SafeType::Symbol.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect(
      SafeType::coerce("abc", SafeType::Symbol.default)
    ).to eql(:abc)
  end

  it "coerces custom types to symbol" do
    class CustomType
      def safe_type
        :safe_type
      end
    end

    class InvalidCustomType; end

    expect(
      SafeType::coerce(CustomType.new, SafeType::Symbol.default)
    ).to eql(:safe_type)
    expect{
      SafeType::coerce(InvalidCustomType.new, SafeType::Symbol.default)
    }.to raise_error(SafeType::CoercionError)
  end

  it "validates the input after coerce" do
    expect{
      SafeType::coerce("abc", SafeType::Symbol.strict(max_length: 2))
    }.to raise_error(SafeType::ValidationError)
  end
end
