# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# ATENÇÃO: Para upload pra LOCAWEB, USE:
# RAILS_GEM_VERSION = "2.2.2" # => e renomeie o arquivo controller/application.rb
#
# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = "2.3.5" unless defined? RAILS_GEM_VERSION
RAILS_GEM_VERSION = "2.3.11" unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), "boot")

# trying to use this plugin...
# require "rubygems"
require "desert"

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  
  # Para carregar modelos dentro de pastas...
  # config.load_paths += Dir["#{RAILS_ROOT}/app/models/[a-z]*"]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "unicode", 
             :lib => "unicode"
  config.gem "mislav-will_paginate",
             :lib => "will_paginate",
             :source => "http://gems.github.com"
  config.gem "weppos-helperful",
             :lib => "helperful",
             :source => "http://gems.github.com"
  config.gem "fastercsv"
  config.gem 'rails-settings', 
             :lib => 'settings'
  config.gem "googlecharts", 
             :lib => "googlecharts"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = "Brasilia"

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_cidade_democratica_session',
    :secret      => 'eef90fb0e479eff0600e81d08b0142bc83b57933fe6e23c0bc702fa90ef4cf339953b51e06d5068fe32f6a43f0a37cc0b8c499171b37c1775f68d70d13a38f86'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :user_observer, :adesao_observer
  
  # The internationalization framework can be changed
  # to have another default locale (standard is :en) or more load paths.
  # All files from config/locales/*.rb,yml are added automatically.
  # config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = "pt-BR"

  $KCODE = "u"
  require "jcode"
end