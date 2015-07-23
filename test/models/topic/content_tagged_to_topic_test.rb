require "test_helper"

describe Topic::ContentTaggedToTopic do
  include RummagerHelpers

  describe "constructing the query params" do
    setup do
      @subtopic_slug = 'business-tax/paye'
      @pagination_options = {}
      @documents = Topic::ContentTaggedToTopic.new(@subtopic_slug, @pagination_options)
    end

    it "filters for the given subtopic" do
      expect_search_params(:filter_specialist_sectors => [@subtopic_slug])
      @documents.send(:search_result)
    end

    it "requests the necessary fields" do
      expect_search_params(:fields => %w(title link public_timestamp format))
      @documents.send(:search_result)
    end
  end

  describe "with a single page of results available" do
    setup do
      @subtopic_slug = 'business-tax/paye'
      rummager_has_documents_for_subtopic(@subtopic_slug, [
        'pay-paye-penalty',
        'pay-paye-tax',
        'pay-psa',
        'employee-tax-codes',
        'payroll-annual-reporting',
      ], page_size: Topic::ContentTaggedToTopic::PAGE_SIZE_TO_GET_EVERYTHING)
    end

    it "returns the documents for the subtopic" do
      expected_titles = [
        'Pay paye penalty',
        'Pay paye tax',
        'Pay psa',
        'Employee tax codes',
        'Payroll annual reporting',
      ]
      assert_equal expected_titles, Topic::ContentTaggedToTopic.new(@subtopic_slug).map(&:title)
    end

    it "provides the title, base_path for each document" do
      documents = Topic::ContentTaggedToTopic.new(@subtopic_slug).to_a

      # Actual values come from rummager helpers.
      assert_equal "/pay-psa", documents[2].base_path
      assert_equal "Employee tax codes", documents[3].title
    end

    it "provides the public_updated_at for each document" do
      documents = Topic::ContentTaggedToTopic.new(@subtopic_slug).to_a

      assert documents[0].public_updated_at.is_a?(Time)

      # Document timestamp value set in rummager helpers
      assert_in_epsilon 1.hour.ago.to_i, documents[0].public_updated_at.to_i, 5
    end
  end

  describe "handling missing fields in the search results" do
    it "handles documents that don't contain the public_timestamp field" do
      result = rummager_document_for_slug('pay-psa')
      result.delete("public_timestamp")

      Collections::Application.config.search_client.stubs(:unified_search).with(
        has_entries(filter_specialist_sectors: ['business-tax/paye'])
      ).returns({
        "results" => [result],
        "start" => 0,
        "total" => 1,
      })

      documents = Topic::ContentTaggedToTopic.new("business-tax/paye")
      assert_equal 1, documents.to_a.size
      assert_equal 'Pay psa', documents.first.title
      assert_nil documents.first.public_updated_at
    end
  end
end