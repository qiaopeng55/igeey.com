class TaggingObserver < ActiveRecord::Observer
  def before_create(tagging)
    tagging.user_id = tagging.taggable.user_id
    tagging.venue_id = tagging.taggable.venue_id
  end
end
