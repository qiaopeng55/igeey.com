require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  
  add_oauth  #dynamic method for confirmation of oauth status
  
  belongs_to  :geo
  has_many :venues,         :foreign_key => :creator_id,:dependent => :destroy
  has_many :records,        :dependent => :destroy
  has_many :plans,          :dependent => :destroy
  has_many :callings,       :dependent => :destroy
  has_many :comments,       :dependent => :destroy
  has_many :topics,         :dependent => :destroy
  has_many :photos,         :dependent => :destroy
  has_many :grants,         :dependent => :destroy
  has_many :badges,         :through => :grants, :source => :badge
  has_many :followings,     :class_name => "Follow",:foreign_key => :user_id
  has_many :follows,        :as => :followable, :dependent => :destroy
  has_many :followers,      :through => :follows, :source => :user
  has_many :sayings,        :dependent => :destroy
  has_many :doings,         :dependent => :destroy
  has_many :syncs,          :dependent => :destroy
  has_many :notifications,  :dependent => :destroy
  has_many :taggings,       :dependent => :destroy
  has_many :tags,           :through => :taggings, :source => :tag
  has_many :events,         :dependent => :destroy
  has_many :questions,      :dependent => :destroy
  has_many :answers,        :dependent => :destroy
  
  has_attached_file :avatar,:styles => {:_48x48 => ["48x48#",:png],:_72x72 => ["72x72#",:png]},
                            :default_url=>"/defaults/:attachment/:style.png",
                            :default_style=> :_48x48,
                            :url=>"/media/:attachment/:id/:style.:extension"
  
  validates :login, :uniqueness => true,
                    :length     => { :within => 1..40,:message => '用户名字数在1至40之间'},
                    :format     => { :with => Authentication.login_regex, :message => '用户名请使用中文和常见的字符' }

  validates :name,  :format     => { :with => Authentication.name_regex, :message => Authentication.bad_name_message },
                    :length     => { :maximum => 100},
                    :allow_nil  => true

  validates :email, :uniqueness => true,
                    :format     => { :with => Authentication.email_regex, :message => '邮箱格式有误'},
                    :length     => { :within => 6..100 ,:message => '邮箱不足6位'}
                    
  validates :avatar_file_name,:format => { :with => /([\w-]+\.(gif|png|jpg))|/ }
  
  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  
  attr_accessible :login, :email, :name, :password, :password_confirmation,:avatar,:avatar_file_name,:geo_id,:signature,:use_local_geo

  default_scope :order => 'follows_count desc'
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) || find_by_email(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  def update_notifications_count
    self.update_attribute(:notifications_count, self.notifications.where(:unread => true).size)
  end
  
  def get_notifications
    Notification.where(:user_id => self.id, :unread => true).order("updated_at desc")
  end
  
  def venues_count
    self.venues.size
  end
  
  def syncs_count
    self.syncs.size
  end  
  
  def followings_count
    self.followings.size
  end  
  
  def influence_count
    [self.callings.map{|c| c.plans.where(:parent_id => nil)},self.plans.map{|p| p.children}].flatten.uniq.size
  end
  
  def douban_count
    self.douban? ? 1 : 0
  end
  
  def sina_count
    self.sina? ? 1 : 0
  end
  
  def inbox
    Message.where(:to_user_id => self.id).order("created_at desc")
  end
  
  def outbox
    Message.where(:from_user_id => self.id).order("created_at desc")
  end
  
  def inbox_unread_count
    Message.where(:to_user_id => self.id, :to_user_has_seen => false).size
  end
  
  def realtime_plans_count
    self.plans.count
  end
  
  def realtime_callings_count
    self.callings.count
  end
  
  def questions_count
    self.questions.count
  end
  
  def answers_count
    self.answers.count
  end
  
  def is_following?(followable)
    self.followings.where(:followable_id => followable.id,:followable_type => followable.class).first.present?
  end

  def is_answered?(question)
    self.answers.where(:question_id => question.id).first.present?
  end

  def user_followings
    self.followings.where(:followable_type => 'User')
  end

  def venue_followings
    self.followings.where(:followable_type => 'Venue')
  end
  
  def tag_followings
    self.followings.where(:followable_type => 'Tag')
  end
  
  def calling_followings
    self.followings.where(:followable_type => 'Calling')
  end
  
  def tag_list
    self.followings.where(:followable_type => 'Tag').map(&:followable).map(&:name)
  end
  
  def has_new_badge?
    self.grants.where(:unread => true).first.present?
  end
    
  def latest_update
    [self.records.first,self.callings.first,self.plans.first].compact.sort{|x,y| y.created_at <=> x.created_at }.first
  end
  
  # Use OAuth::AccessToken to access oauth api. powered by oauth_side 
  def send_to_douban_miniblog(message)
    content = "<?xml version='1.0' encoding='UTF-8'?><entry xmlns:ns0='http://www.w3.org/2005/Atom' xmlns:db='http://www.douban.com/xmlns/'><content>#{message}</content></entry>"
    self.douban.post('http://api.douban.com/miniblog/saying',content, {"Content-Type" =>  "application/atom+xml"}  )
  end
  
  def send_to_sina_miniblog(message)
    self.sina.post('http://api.t.sina.com.cn/statuses/update.xml',{:status => message}, {"Content-Type" =>  "application/atom+xml"}  )
  end

  def send_to_miniblogs(message,options={})
    self.send_to_douban_miniblog(message) if (options[:to_douban] && douban?)
    self.send_to_sina_miniblog(message) if (options[:to_sina] && sina?)
  end
  
  def init_userdata_from(token)
    self.send_to_douban_miniblog(token) if token.site == 'douban'
    self.send_to_sina_miniblog(token) if token.site == 'sina'
  end
  
  def check_badge_condition_on(*args)
    args.each do |condition_factor|
      Badge.where(:condition_factor => condition_factor).each do |badge|
        if (self.method("#{badge.condition_factor}").call >= badge.condition_number)
          self.grants.build(:badge_id => badge.id).save
        end
      end
    end
  end
  
  def generate_password(length)
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
    password = ''
    length.times do |i|
      password << chars[rand(62)]
    end
    password
  end
  
  def reset_password!
    self.password = self.password_confirmation = generate_password(6)
    self.encrypt_password
    self.password = nil
    Mailer.reset_password(self,self.password_confirmation).deliver if self.save
  end
  
  def has_voted_to?(voteable)
    Vote.where(:user_id => self.id, :voteable_id => voteable.id).present?
  end
    
  define_index do
    indexes login
    indexes signature
    indexes geo.name,:as => :city
    has follows_count
    has geo_id
  end

  protected
  
end