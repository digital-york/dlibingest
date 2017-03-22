namespace :migration_tasks do


require_relative '../../app/models/foxml_reader.rb'

task :default do
  puts "Hello Peri!"
end

task :greet do
	puts "doing the greet task"
end

task :make_collection_structure, [:mapping_path]  => :environment do|t, args|
puts "Args were: #{args}"
	r = FoxmlReader.new
	r.make_collection_structure(args[:mapping_path])
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

#calls a test method
task :make_collection => :environment do
	r = FoxmlReader.new
	r.make_collection
end

end #end of tasks