class Photo < ActiveRecord::Base
  belongs_to :user,      :counter_cache => true
  belongs_to :venue,     :counter_cache => true
  belongs_to :imageable, :polymorphic => true
  has_many   :comments, :as => :commentable, :dependent => :destroy
  has_many   :votes,    :as => :voteable,    :dependent => :destroy
  has_many   :notifications, :as => :notifiable, :dependent => :destroy
  
  acts_as_eventable
  acts_as_taggable
  acts_as_ownable
  
  default_scope :order => 'created_at DESC'
  
  has_attached_file :photo, :styles => {:_90x64 => ["90x64#"],:max500x400 => ["500x400>"]},
                            :url=>"/media/:attachment/:id/:style.:extension",
                            :default_style=> :_90x64,
                            :default_url=>"/defaults/:attachment/:style.png"
                            
  validates :photo_file_name, :presence   => true,:format => { :with => /([\w-]+\.(gif|png|jpg))|/ }
  validates :venue_id, :presence   => true
      
  def self.tag_list
    Tagging.where(:taggable_type => self.to_s).limit(5).map(&:tag).map(&:name)
  end

end
