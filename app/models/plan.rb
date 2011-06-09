class Plan < ActiveRecord::Base
  belongs_to :venue
  belongs_to :task
  belongs_to :user,     :counter_cache => true
  belongs_to :parent,   :class_name => 'Plan',:foreign_key => :parent_id
  has_one    :record
  has_many   :syncs,    :as => :syncable,    :dependent => :destroy
  has_many   :plans
  has_many   :children, :class_name => 'Plan' ,:foreign_key => :parent_id
  
  acts_as_ownable
  
  default_scope :order => 'created_at DESC'
  
  scope :undone ,where(:is_done => false)
  
  validates :task_id, :content, :presence => true
  validates :user_id,    :presence   => true,:uniqueness => {:scope => :task_id}
  
  def number
    {'money'=> money,'goods'=> goods,'time'=> 1}[for_what] || 0
  end
  
  def formatted_plan_at
    date = self.plan_at
    "#{date.year == Date.today.year ? '' : "#{date.year}年"}#{date.month}月#{date.day}日"
  end

  def status
    self.task.status
  end
  
  def description
    "要参加#{task.venue.name}的行动：#{self.task.title}"
  end

end