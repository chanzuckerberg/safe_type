require 'safe_type'

describe :coerce_date do
  it "coerces primitive types to date" do
    date = Date.new(2018, 6, 20)
    expect(
      SafeType::coerce(nil, SafeType::Date.default(date))
    ).to eql(date)
    expect{
      SafeType::coerce(nil, SafeType::Date.strict)
    }.to raise_error(SafeType::EmptyValueError)
    expect(
      SafeType::coerce("2018-06-20", SafeType::Date.default)
    ).to eql(date)
    expect(
      SafeType::coerce("2018/06/20", SafeType::Date.default)
    ).to eql(date)
  end

  it "validates the input after coerce" do
    expect(
      SafeType::coerce("2018/06/20", SafeType::Date.strict(from: Date.new(2018, 5, 30)))
    ).to eql(Date.new(2018, 6, 20))
    expect{
      SafeType::coerce("2018/06/20", SafeType::Date.strict(to: Date.new(2018, 5, 30)))
    }.to raise_error(SafeType::ValidationError)
    expect{
      SafeType::coerce("2018/06/20", SafeType::Date.strict(from: Date.new(2018, 6, 30)))
    }.to raise_error(SafeType::ValidationError)
  end
end
