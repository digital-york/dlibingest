rails_env = ENV['RAILS_ENV'] || 'development'
resque_config = YAML.load_file(File.join(__dir__, '../', 'resque.yml'))
Resque.redis = resque_config[rails_env]

