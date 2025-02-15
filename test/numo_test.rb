require_relative "test_helper"

class NumoTest < Minitest::Test
  def test_series_int
    s = Polars::Series.new([1, 2, 3])
    assert_kind_of Numo::Int64, s.to_numo
    assert_equal s.to_a, s.to_numo.to_a
  end

  def test_series_int_nil
    s = Polars::Series.new([1, nil, 3])
    assert_kind_of Numo::DFloat, s.to_numo
    assert s.to_numo[1].nan?
  end

  def test_series_float
    s = Polars::Series.new([1.5, 2.5, 3.5])
    assert_kind_of Numo::DFloat, s.to_numo
    assert_equal s.to_a, s.to_numo.to_a
  end

  def test_series_bool
    s = Polars::Series.new([true, false, true])
    assert_kind_of Numo::Bit, s.to_numo
    assert_equal [1, 0, 1], s.to_numo.to_a
  end

  def test_series_str
    s = Polars::Series.new(["one", nil, "three"])
    assert_kind_of Numo::RObject, s.to_numo
    assert_equal s.to_a, s.to_numo.to_a
  end

  def test_series_date
    today = Date.today
    s = Polars::Series.new([today - 2, nil, today])
    assert_kind_of Numo::RObject, s.to_numo
    assert_equal s.to_a, s.to_numo.to_a
  end

  def test_data_frame
    df = Polars::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_kind_of Numo::RObject, df.to_numo
    assert_equal [[1, "one"], [2, "two"], [3, "three"]], df.to_numo.to_a
  end
end
