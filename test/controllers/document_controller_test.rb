require "test_helper"

class DocumentControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get document_index_url
    assert_response :success
  end

  test "should get new" do
    get document_new_url
    assert_response :success
  end

  test "should get create" do
    get document_create_url
    assert_response :success
  end

  test "should get destroy" do
    get document_destroy_url
    assert_response :success
  end
end
