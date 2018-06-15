require 'test_helper'

describe Organisations::PeoplePresenter do
  include RummagerHelpers
  include OrganisationHelpers

  describe '#formatted_minister_data' do
    before :each do
      content_item = ContentItem.new(organisation_with_ministers)
      organisation = Organisation.new(content_item)
      @people_presenter = Organisations::PeoplePresenter.new(organisation)
    end

    it 'formats data for image card component' do
      expected = {
        title: "Our ministers",
        people: {
          brand: "attorney-generals-office",
          href: "/government/people/oliver-dowden",
          image_src: "/photo/oliver-dowden",
          image_alt: "Oliver Dowden CBE MP",
          description: nil,
          metadata: nil,
          context: nil,
          heading_text: "Oliver Dowden CBE MP",
          heading_level: 3,
          extra_links_no_indent: true,
          extra_links: [
            {
              text: "Parliamentary Secretary (Minister for Implementation)",
              href: "/government/ministers/parliamentary-secretary"
            }
          ]
        }
      }

      assert_equal expected[:title], @people_presenter.all_people.first[:title]
      assert_equal expected[:people], @people_presenter.all_people.first[:people][0]
    end

    it 'handles ministers with multiple roles' do
      expected = {
        title: "Our ministers",
        people: {
          brand: "attorney-generals-office",
          href: "/government/people/theresa-may",
          image_src: "/photo/theresa-may",
          image_alt: "Theresa May MP",
          description: nil,
          metadata: nil,
          context: "The Rt Hon",
          heading_text: "Theresa May MP",
          heading_level: 3,
          extra_links_no_indent: true,
          extra_links: [
            {
              text: "Prime Minister",
              href: "/government/ministers/prime-minister"
            },
            {
              text: "Minister for the Civil Service",
              href: "/government/ministers/minister-for-the-civil-service"
            }
          ]
        }
      }

      assert_equal expected[:title], @people_presenter.all_people.first[:title]
      assert_equal expected[:people], @people_presenter.all_people.first[:people][2]
    end

    it 'returns minister without image if no image available' do
      expected = {
        title: "Our ministers",
        people: {
          brand: "attorney-generals-office",
          href: "/government/people/stuart-andrew",
          description: nil,
          metadata: nil,
          context: nil,
          heading_text: "Stuart Andrew MP",
          heading_level: 3,
          extra_links_no_indent: true,
          extra_links: [
            {
              text: "Parliamentary Under Secretary of State",
              href: "/government/ministers/parliamentary-under-secretary-of-state--94"
            },
          ]
        }
      }

      assert_equal expected[:title], @people_presenter.all_people.first[:title]
      assert_equal expected[:people], @people_presenter.all_people.first[:people][1]
    end
  end
end
