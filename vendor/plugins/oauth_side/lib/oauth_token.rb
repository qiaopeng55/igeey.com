class OauthToken < ActiveRecord::Base

  attr_accessor :site_config
  
  def self.request_by user_id, site
    record = find_by_user_id_and_site(user_id,site) || self.create(:user_id => user_id, :site => site)
    raise "用户已经开通" unless record.access_token.nil? || record.user_id.nil?
    record.request_key = nil
    token = record.request_token
    token.authorize_url 
  end

  # 获取当前的rquest_token对象，如果没有就创建一个
  def request_token
    return @request if @request

    if request_key.nil?
      @request = consumer.get_request_token
      update_attributes :request_key => @request.token, :request_secret => @request.secret
    else
      @request = OAuth::RequestToken.new( consumer, request_key, request_secret )
    end
    @request
  end

  # 获取当前的access_token对象，如果没有就返回nil
  def access_token
    @access ||= OAuth::AccessToken.new( consumer, access_key, access_secret ) unless access_key.nil?
  end

  # 获取访问授权信息，从这里开始系统就可以提供对用户的服务了
  def authorize oauth_verifier = nil
    @access = request_token.get_access_token :oauth_verifier => oauth_verifier
    update_attributes :access_key => @access.token, :access_secret => @access.secret
    @access
  end
  
  # 获取 concumer
  def consumer
    @consumer ||= lambda{|config|
      OAuth::Consumer.new(
        config[:api_key],
        config[:api_key_secret],
        config.only(:site,:request_token_path,:access_token_path,:authorize_path,:signature_method,:scheme,:realm)
      )
    }.call(Rails.oauth[site.to_sym])
  end
  
  # 获取连接网站的唯一用户标识
  def get_site_unique_id
    case self.site
    when 'sina'
      get_sina_unique_id
    when 'douban'
      get_douban_unique_id
    end
  end
  
  def get_douban_unique_id
    /<db:uid>(.*)<\/db:uid>/.match(self.access_token.get('http://api.douban.com/people/%40me').body)[1]
  end  
  
  def get_sina_unique_id
    /<id>(.*)<\/id>/.match(self.access_token.get('http://api.t.sina.com.cn/account/verify_credentials.xml').body)[1]
  end
  
end
