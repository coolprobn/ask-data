# frozen_string_literal: true

require "test_helper"

class QuestionsTest < ActionDispatch::IntegrationTest
  def teardown
    QuestionsController.nl_query_executor = nil
    super
  end

  test "ask renders at root" do
    get root_path
    assert_response :success
    assert_match(/Ask Data/i, @response.body)
  end

  test "ask renders at /ask" do
    get ask_path
    assert_response :success
    assert_match(/Ask Data/i, @response.body)
  end

  test "create shows clarification when question is ambiguous" do
    post ask_path, params: { question: "hi" }
    assert_response :success
    assert_match(/short on detail|examples below/i, @response.body)
  end

  test "create renders result table when pipeline returns success" do
    result = NlQuery::QueryResult.new(
      outcome: :success,
      user_message: nil,
      interpretation: NlQuery::ProductPolicy::TRUST_COPY_SUCCESS,
      suggestions: nil,
      support_id: "00000000-0000-0000-0000-000000000001",
      sql: "SELECT 1 AS n",
      internal_note: nil
    )
    fake = Object.new
    fake.define_singleton_method(:execute) { |**_| result }
    QuestionsController.nl_query_executor = fake

    post ask_path, params: { question: "List all customers who have placed orders in the demo shop" }
    assert_response :success
    assert_match(/<th[^>]*>\s*n\s*<\/th>/i, @response.body)
    assert_match(/<td[^>]*>\s*1\s*<\/td>/, @response.body)
    refute_match(/```sql/i, @response.body)
  end

  test "create shows safe message when execution fails" do
    result = NlQuery::QueryResult.new(
      outcome: :success,
      user_message: nil,
      interpretation: NlQuery::ProductPolicy::TRUST_COPY_SUCCESS,
      suggestions: nil,
      support_id: "00000000-0000-0000-0000-000000000002",
      sql: "SELECT 1/0 AS n",
      internal_note: nil
    )
    fake = Object.new
    fake.define_singleton_method(:execute) { |**_| result }
    QuestionsController.nl_query_executor = fake

    post ask_path, params: { question: "List all customers who have placed orders in the demo shop" }
    assert_response :success
    assert_match(/couldn’t run that query/i, @response.body)
  end
end
