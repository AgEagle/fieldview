require File.expand_path('../test_helper', __FILE__)

class TestBoundary < Minitest::Test
  FIXTURE = API_FIXTURES.fetch(:boundary_one)
  def test_initialization
    boundary = FieldView::Boundary.new(FIXTURE)
  
    assert_equal FIXTURE[:id], boundary.id
    assert_equal 58.923473472390256, boundary.area
    assert_equal "ac", boundary.units
    assert_equal 2, boundary.centroid.coordinates.length
    assert boundary.centroid.point?
    assert_equal 2, boundary.geometry.coordinates.length
    assert boundary.geometry.multi_polygon?
    assert boundary.geometry.multi_polygon? != boundary.centroid.multi_polygon?, "make sure they are different types"
  end
end