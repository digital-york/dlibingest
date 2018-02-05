namespace :custom_tasks do


require_relative '../../app/helpers/migration/custom_migrations.rb'


task :default do
  puts "Hello Peri!"
end

task :greet do
	puts "doing the greet task"
end


task :migrate_bhutan_thesis, [:collection_id,:server_url,:user] => :environment  do|t, args|
puts "Args were: #{args}"
	r = CustomMigrations.new
	r.migrate_bhutan_thesis_with_content_urls(args[:collection_id],args[:server_url],args[:user])
end



end #end of tasks