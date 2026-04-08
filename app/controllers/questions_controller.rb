# frozen_string_literal: true

class QuestionsController < ApplicationController
  class << self
    # Integration tests set a fake object responding to #execute(question:, schema_snapshot:)
    attr_accessor :nl_query_executor
  end

  def ask
    assign_ask_state
  end

  def create
    assign_ask_state
    schema = NlQuery::SchemaSnapshot.for_llm
    result = nl_query.execute(question: @question, schema_snapshot: schema)
    @nl_result = result

    if result.success?
      begin
        @columns, @rows = NlQuery::RunQuery.perform(result.sql)
      rescue NlQuery::RunQuery::ExecutionError
        @execution_error = NlQuery::ProductPolicy::MESSAGES[:execution_failed]
      end
    end

    render :ask
  end

  private

  def assign_ask_state
    @question = params[:question].to_s
    @nl_result = nil
    @columns = nil
    @rows = nil
    @execution_error = nil
  end

  def nl_query
    self.class.nl_query_executor || NlQuery::NaturalLanguageQuery.new
  end
end
