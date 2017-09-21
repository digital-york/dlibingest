namespace :migration_tasks do


require_relative '../../app/models/foxml_reader.rb'
require_relative '../../app/models/exam_paper_migrator.rb'


task :default do
  puts "Hello Peri!"
end

task :greet do
	puts "doing the greet task"
end

#calls a test method, definable in foxml_reader
task :test => :environment do
	r = FoxmlReader.new
	r.test
end

task :make_collection_structure, [:mapping_path,:foxpath]  => :environment do|t, args|
puts "Args were: #{args}"
	r = FoxmlReader.new
	r.make_exam_collection_structure(args[:mapping_path],args[:foxpath])
end

task :make_exam_collection_structure, [:mapping_path,:foxpath]  => :environment do|t, args|
puts "Args were: #{args}"
	e = ExamPaperMigrator.new
	e.make_exam_collection_structure(args[:mapping_path],args[:foxpath])
end

task :migrate_lots_of_theses_with_content_url, [:dirpath,:donedirpath,:contentserverurl,:collection_mapping_doc] => :environment  do|t, args|
puts "Args were: #{args}"
puts "need to do sommat here"
r = FoxmlReader.new
r.migrate_lots_of_theses_with_content_url(args[:dirpath],args[:donedirpath],args[:contentserverurl],args[:collection_mapping_doc])
end

task :migrate_lots_of_theses, [:dirpath,:donedirpath,:contentpath,:collection_mapping_doc] => :environment  do|t, args|
puts "Args were: #{args}"
puts "need to do sommat here"
r = FoxmlReader.new
r.migrate_lots_of_theses(args[:dirpath],args[:donedirpath],args[:contentpath],args[:collection_mapping_doc])
end

task :migrate_thesis_with_content_url, [:path,:contentserverurl,:collection_mapping] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate_thesis_with_content_url(args[:path],args[:contentserverurl],args[:collection_mapping])
end

task :migrate_thesis, [:path,:contentpath,:collection_mapping] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate_thesis(args[:path],args[:contentpath],args[:collection_mapping])
end

#use this to add a new child method that was in the former fedora collection structure but missed out of the new structure
task :recreate_child_collection, [:former_pid,:title,:parent_id,:collection_mapping_doc] => :environment do|t, args|
puts "Args were: #{args}"
	r = FoxmlReader.new
	r.recreate_child_collection(args[:former_pid],args[:title],args[:parent_id],args[:collection_mapping_doc])
end

#use this to add a new child collection that was created in the gui into another collection. not for migrated collections.
task :add_childcollection_to_parent, [:child_id,:parent_id] => :environment do|t, args|
puts "Args were: #{args}"
	r = FoxmlReader.new
	r.add_new_childcollection_to_parent(args[:child_id],args[:parent_id])
end

end #end of tasks