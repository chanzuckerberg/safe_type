require 'safe_type'

describe :coerce_date_time do
  it "coerces primitive types to date time" do
    date = DateTime.new(2018, 6, 20)
    expect(
      SafeType::coerce(nil, SafeType::DateTime.default(date))
    ).to eql(date)
    expect{
      SafeType::coerce(nil, SafeType::DateTime.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect(
      SafeType::coerce("2018-06-20", SafeType::DateTime.default)
    ).to eql(date)
    expect(
      SafeType::coerce("2018/06/20", SafeType::DateTime.default)
    ).to eql(date)
  end

  it "validates the input after coerce" do
    expect(
      SafeType::coerce("2018/06/20", SafeType::DateTime.strict(from: DateTime.new(2018, 5, 30)))
    ).to eql(DateTime.new(2018, 6, 20))
    expect{
      SafeType::coerce("2018/06/20", SafeType::DateTime.strict(to: DateTime.new(2018, 5, 30)))
    }.to raise_error(SafeType::ValidationError)
    expect{
      SafeType::coerce("2018/06/20", SafeType::DateTime.strict(from: DateTime.new(2018, 6, 30)))
    }.to raise_error(SafeType::ValidationError)
  end
end
