require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Igeey
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_calling, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers = [:user_observer,
                                      :comment_observer,
                                      :task_observer,
                                      :plan_observer,
                                      :record_observer,
                                      :photo_observer,
                                      :venue_observer,
                                      :sync_observer,
                                      :oauth_token_observer,
                                      :follow_observer,
                                      :notification_observer,
                                      :tagging_observer,
                                      :action_observer,
                                      :answer_observer,
                                      :question_observer,
                                      ]
    
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone =  'Beijing'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :zh

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.middleware.use ExceptionNotifier,
      :email_prefix => "[Error] ",
      :sender_address => %{"notifier" <mail@igeey.com>},
      :exception_recipients => YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]['developer_mail'].to_a
      
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += Dir["#{config.root}/lib/autoload/"]
    config.generators do |g|
        g.fixture_replacement :factory_girl, :dir => "spec/factories"
    end
  end
end
