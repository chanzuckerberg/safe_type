require 'safe_type'

describe :coerce_boolean do
  it "coerces primitive types to boolean" do
    expect(
      SafeType::coerce(nil, SafeType::Boolean.default(false))
    ).to eql(false)
    expect{
      SafeType::coerce(nil, SafeType::Boolean.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect(
      SafeType::coerce("true", SafeType::Boolean.default)
    ).to eql(true)
    expect(
      SafeType::coerce("TRUE", SafeType::Boolean.default)
    ).to eql(true)
    expect{
      SafeType::coerce("what", SafeType::Boolean.default)
    }.to raise_error(SafeType::CoercionError)
  end

  it "coerces custom types to boolean" do
    class CustomType
      def safe_type
        false
      end
    end

    expect(
      SafeType::coerce(CustomType.new, SafeType::Boolean.default)
    ).to eql(false)
  end
end
