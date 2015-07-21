class ListSet
  include Enumerable

  FORMATS_TO_EXCLUDE = %w(
    fatality_notice
    government_response
    news_story
    press_release
    speech
    statement
    world_location_news_article
  ).to_set

  def initialize(tag_type, tag_slug, group_data)
    @tag_type = tag_type
    @tag_slug = tag_slug
    @group_data = group_data || []
  end

  def each
    lists.each do |l|
      yield l
    end
  end

  def curated?
    @group_data.any?
  end

  private

  def lists
    # TODO: Remove Content API as a dependency
    #
    # The intention is to remove the Content API as a dependency
    # on the Collections application altogether. All uses
    # of the Content API are now within the ListSet::Section class
    # below.
    @_lists ||= if @tag_type == "specialist_sector"
      ListSet::Specialist.new(@tag_slug, @group_data)
    else
      ListSet::Section.new(@tag_type, @tag_slug, @group_data)
    end
  end
end
