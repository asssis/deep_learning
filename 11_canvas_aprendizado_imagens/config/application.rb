require_relative 'boot'
require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
Bundler.require(*Rails.groups)
module SketchLab
  class Application < Rails::Application
    config.load_defaults 8.1
    config.secret_key_base = ENV.fetch('SECRET_KEY_BASE') { 'sketch-lab-local-development-' * 4 }
    config.hosts = ['localhost', '127.0.0.1', 'www.example.com']
    config.autoload_lib(ignore: %w[assets tasks])
    config.x.sketch_storage = root.join('storage')
  end
end
