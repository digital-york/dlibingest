namespace :migration_tasks do
#require '/vagrant/merged_cc/app/models/foxml_reader.rb'
task :default do
  puts "Hello Peri!"
end

task :greet do
	puts "doing the greet task"
end

task :make_collection_structure => :environment do
	r = FoxmlReader.new
	r.make_collection_structure
end



task :migrate, [:path,:collection] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate(args[:path],args[:collection])
end

task :migrate_thesis, [:path,:collection] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate_thesis(args[:path],args[:collection])
end

task :testme => :environment do
	r = FoxmlReader.new
	r.testme
end

task :testupload => :environment do
	r = FoxmlReader.new
	r.test_pdf_upload
end

task :vanilla => :environment do
	r = FoxmlReader.new
	r.vanilla
end

task :strawberry => :environment do
	r = FoxmlReader.new
	r.strawberry
end

task :make_collection => :environment do
	r = FoxmlReader.new
	r.make_collection
end

end #end of tasks