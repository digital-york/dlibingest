namespace :migration_tasks do
require '/vagrant/fresh_dlibingest/dlibingest/app/models/foxml_reader.rb'
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




task :migrate_lots_of_theses, [:dirpath,:collection_mapping_doc] => :environment  do|t, args|
puts "Args were: #{args}"
puts "need to do sommat here"
r = FoxmlReader.new
r.migrate_lots_of_theses(args[:dirpath],args[:collection_mapping_doc])
end



task :migrate_thesis, [:path,:collection_mapping] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate_thesis(args[:path],args[:collection_mapping])
end

task :testme => :environment do
	r = FoxmlReader.new
	r.testme
end

task :anyonecantestupload, [:username,:collection_id,:filepath] => :environment do|t, args|
puts "Args were: #{args}"
	r = FoxmlReader.new
	r.test_pdf_upload_anyone(args[:username],args[:collection_id],args[:filepath])
end

task :testupload => :environment do
	r = FoxmlReader.new
	r.test_pdf_upload
end



task :make_collection => :environment do
	r = FoxmlReader.new
	r.make_collection
end

end #end of tasks