require 'safe_type'

describe :coerce_time do
  it "coerces primitive types to time" do
    time = Time.new(2018, 6, 20)
    expect(
      SafeType::coerce(nil, SafeType::Time.default(time))
    ).to eql(time)
    expect{
      SafeType::coerce(nil, SafeType::Time.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect(
      SafeType::coerce("2018-06-20", SafeType::Time.default)
    ).to eql(time)
    expect(
      SafeType::coerce("2018/06/20", SafeType::Time.default)
    ).to eql(time)
  end

  it "valitimes the input after coerce" do
    expect(
      SafeType::coerce("2018/06/20", SafeType::Time.strict(from: Time.new(2018, 5, 30)))
    ).to eql(Time.new(2018, 6, 20))
    expect{
      SafeType::coerce("2018/06/20", SafeType::Time.strict(to: Time.new(2018, 5, 30)))
    }.to raise_error(SafeType::ValidationError)
    expect{
      SafeType::coerce("2018/06/20", SafeType::Time.strict(from: Time.new(2018, 6, 30)))
    }.to raise_error(SafeType::ValidationError)
  end
end
