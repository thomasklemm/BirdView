require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Tweetbox
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    # TODO: Some paths can be removed here
    config.autoload_paths += Dir["#{config.root}/app/models/**/",
                                 "#{config.root}/app/decorators/",
                                 "#{config.root}/app/decorators/**/",
                                 "#{config.root}/app/facades/",
                                 "#{config.root}/lib",
                                 "#{config.root}/lib/**/"]

    # Default timezone
    config.active_record.default_timezone = :utc

    # Use Pry console
    # console do
    #   require "pry"
    #   config.console = Pry
    # end

    # Generator options
    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :fabrication
      g.helper false
      g.stylesheets false
      g.javascript_engine false
      g.view_specs false
      g.assets false # Rails 4
    end

    # Insert Rack::Deflater as the first middleware
    # to gzip all responses, including assets
    config.middleware.insert 0, Rack::Deflater
  end
end
