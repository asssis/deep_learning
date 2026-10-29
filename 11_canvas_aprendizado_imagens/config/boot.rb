ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
# Porta padrão deste laboratório; -p ou PORT continuam podendo sobrescrever.
ENV['PORT'] ||= '3001'
require 'bundler/setup'
