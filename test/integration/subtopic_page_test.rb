require 'integration_test_helper'

class SubtopicPageTest < ActionDispatch::IntegrationTest
  include RummagerHelpers

  def oil_and_gas_subtopic_item(subtopic_slug, params = {})
    base = {
      content_id: "content-id-for-#{subtopic_slug}",
      base_path: "/topic/oil-and-gas/#{subtopic_slug}",
      title: subtopic_slug.humanize,
      description: "Offshore drilling and exploration",
      format: "topic",
      public_updated_at: 10.days.ago.iso8601,
      details: {
        groups: [],
      },
      links: {
        "parent" => [
          "title" => "Oil and Gas",
          "base_path" => "/topic/oil-and-gas",
        ]
      },
    }
    base[:details].merge!(params.delete(:details)) if params.has_key?(:details)
    base.merge(params)
  end

  before do
    rummager_has_documents_for_subtopic(
      'content-id-for-offshore',
      [
        'oil-rig-safety-requirements',
        'oil-rig-staffing',
        'north-sea-shipping-lanes',
        'undersea-piping-restrictions'
      ],
      page_size: RummagerSearch::PAGE_SIZE_TO_GET_EVERYTHING
    )
  end

  it "renders a curated subtopic" do
    # Given a curated subtopic exists
    content_store_has_item("/topic/oil-and-gas/offshore", oil_and_gas_subtopic_item("offshore", details: {
      groups: [
        {
          name: "Oil rigs",
          contents: [
            "/oil-rig-staffing",
            "/oil-rig-safety-requirements",
          ],
        },
        {
          name: "Piping",
          contents: [
            "/undersea-piping-restrictions",
          ],
        },
      ]
    }))

    stub_topic_organisations('oil-and-gas/offshore', 'content-id-for-offshore')

    # When I visit the subtopic page
    visit "/topic/oil-and-gas/offshore"

    # Then I should see the subtopic metadata
    within '.page-header' do
      within 'h1' do
        assert page.has_content?("Oil and Gas")
        assert page.has_content?("Offshore")
      end

      within '.metadata' do
        # The orgs are fixed in the rummager test helpers
        assert page.has_link?("Department of Energy & Climate Change")
        assert page.has_link?("Foreign & Commonwealth Office")
      end
    end

    # And I should see the curated content for the subtopic
    assert page.has_link?("Oil rig staffing", href: "/oil-rig-staffing")
    assert page.has_link?("Oil rig safety requirements", href: "/oil-rig-safety-requirements")
    assert page.has_link?("Undersea piping restrictions", href: "/undersea-piping-restrictions")

    refute page.has_link?("North sea shipping lanes")

    assert page.has_selector?(shared_component_selector('breadcrumbs'))
  end

  it "renders a non-curated subtopic" do
    # Given a non-curated subtopic exists
    content_store_has_item("/topic/oil-and-gas/offshore", oil_and_gas_subtopic_item("offshore"))
    stub_topic_organisations('oil-and-gas/offshore', 'content-id-for-offshore')

    # When I visit the subtopic page
    visit "/topic/oil-and-gas/offshore"

    # Then I should see the subtopic metadata
    within '.page-header' do
      within 'h1' do
        assert page.has_content?("Oil and Gas")
        assert page.has_content?("Offshore")
      end

      within '.metadata' do
        # The orgs are fixed in the rummager test helpers
        assert page.has_link?("Department of Energy & Climate Change")
        assert page.has_link?("Foreign & Commonwealth Office")
      end
    end

    # And I should see all content for the subtopic
    assert page.has_link?("Oil rig staffing", href: "/oil-rig-staffing")
    assert page.has_link?("Oil rig safety requirements", href: "/oil-rig-safety-requirements")
    assert page.has_link?("North sea shipping lanes", href: "/north-sea-shipping-lanes")
    assert page.has_link?("Undersea piping restrictions", href: "/undersea-piping-restrictions")

    assert page.has_selector?(shared_component_selector('breadcrumbs'))
  end

  describe "latest page for a subtopic" do
    setup do
      content_store_has_item("/topic/oil-and-gas/offshore", oil_and_gas_subtopic_item("offshore"))
      stub_topic_organisations('oil-and-gas/offshore', 'content-id-for-offshore')
    end

    it "displays the latest page" do
      # Given there is latest content for a subtopic
      rummager_has_latest_documents_for_subtopic("content-id-for-offshore", [
        "oil-and-gas-uk-field-data",
        "oil-and-gas-wells",
        "oil-and-gas-fields-and-field-development",
        "oil-and-gas-geoscientific-data"
      ])

      # When I view the latest page for a subtopic
      visit "/topic/oil-and-gas/offshore"
      click_on "See latest changes to this content"

      # Then I should see the subtopic metadata
      within '.page-header' do
        within 'h1' do
          assert page.has_content?("Offshore: latest documents")
        end

        within '.metadata' do
          # The orgs are fixed in the rummager test helpers
          assert page.has_link?("Department of Energy & Climate Change")
          assert page.has_link?("Foreign & Commonwealth Office")
        end
      end

      # And I should see the latest documents for the subtopic in date order
      titles = page.all(".changed-documents li h3").map(&:text)
      expected_titles = [
        'Oil and gas uk field data',
        'Oil and gas wells',
        'Oil and gas fields and field development',
        'Oil and gas geoscientific data'
      ]
      assert_equal expected_titles, titles
    end

    it "paginates the results" do
      # Given there is latest content for a subtopic
      rummager_has_latest_documents_for_subtopic(
        "content-id-for-offshore",
        (1..55).map { |n| "document-#{n}" }
      )

      # When I view the latest page for a subtopic
      visit "/topic/oil-and-gas/offshore"
      click_on "See latest changes to this content"

      # Then I should see the first 50 documents
      within '.changed-documents' do
        assert page.has_content?("Document 1")
        assert page.has_content?("Document 50")
        refute page.has_content?("Document 51")
      end

      # When I go to the next page
      click_on "Next page"

      # Then I should see the remaining documents
      within '.changed-documents' do
        assert page.has_content?("Document 51")
        assert page.has_content?("Document 55")
        refute page.has_content?("Document 1")
        refute page.has_content?("Document 50")
      end

      # When I go back to the first page
      click_on "Previous page"

      # Then I should see the first 50 documents again
      within '.changed-documents' do
        assert page.has_content?("Document 1")
        assert page.has_content?("Document 50")
        refute page.has_content?("Document 51")
      end
    end
  end
end
