namespace :migration_tasks do


require_relative '../../app/models/foxml_reader.rb'
require_relative '../../app/models/exam_paper_migrator.rb'
require_relative '../../app/models/common_migration_methods.rb'


task :default do
  puts "Hello Peri!"
end

task :greet do
	puts "doing the greet task"
end

task :test_exams => :environment do
puts "rake task says hi"
	e = ExamPaperMigrator.new
	e.say_hello
end

#calls a test method, definable in foxml_reader
task :test_theses => :environment do
	r = FoxmlReader.new
	r.test
end

task :make_collection_structure, [:mapping_path,:foxpath]  => :environment do|t, args|
puts "Args were: #{args}"
	r = FoxmlReader.new
	r.make_exam_collection_structure(args[:mapping_path],args[:foxpath])
end

task :make_restricted_exam_collection_structure, [:mapping_path,:foxpath]  => :environment do|t, args|
puts "Args were: #{args}"
	e = ExamPaperMigrator.new
	e.make_restricted_exam_collection_structure(args[:mapping_path],args[:foxpath])
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

task :migrate_lots_of_exams, [:dirpath,:donedirpath,:contentpath,:collection_mapping_doc] => :environment  do|t, args|
puts "Args were: #{args}"
e = ExamPaperMigrator.new
e.migrate_lots_of_exams(args[:dirpath],args[:donedirpath],args[:contentpath],args[:collection_mapping_doc])
end

task :migrate_lots_of_theses, [:dirpath,:donedirpath,:contentpath,:collection_mapping_doc] => :environment  do|t, args|
puts "Args were: #{args}"
puts "need to do sommat here"
r = FoxmlReader.new
r.migrate_lots_of_theses(args[:dirpath],args[:donedirpath],args[:contentpath],args[:collection_mapping_doc])
end

task :migrate_thesis, [:path,:contentserverurl,:collection_mapping] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate_thesis_with_content_url(args[:path],args[:contentserverurl],args[:collection_mapping])
end

task :migrate_thesis_embedded_only, [:path,:contentpath,:collection_mapping] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate_thesis(args[:path],args[:contentpath],args[:collection_mapping])
end

task :migrate_exam_paper, [:path,:contentpath,:collection_mapping] => :environment  do|t, args|
puts "Hi there. Args were: #{args}"
	e = ExamPaperMigrator.new
	e.migrate_exam(args[:path],args[:contentpath],args[:collection_mapping])
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

#write list of every datastream in a folder of objects
task :list_datastreams, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	c = CommonMigrationMethods.new
	c.list_all_ds_in_set(args[:foxmlfolderpath],args[:outputfilename])
end

#write list of every variant datastream label in a folder of objects
task :list_datastream_labels, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	c = CommonMigrationMethods.new
	c.list_all_labels_in_set(args[:foxmlfolderpath],args[:outputfilename])
end

#check for format values to see if any non pdf
task :list_format_values, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	c = CommonMigrationMethods.new
	c.check_format_values(args[:foxmlfolderpath],args[:outputfilename])
end

task :list_dc_creator_values, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	c = CommonMigrationMethods.new
	c.list_dc_creator_values(args[:foxmlfolderpath],args[:outputfilename])
end


task :list_dc_type_values, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	c = CommonMigrationMethods.new
	c.list_dc_type_values(args[:foxmlfolderpath],args[:outputfilename])
end

#check the elements most likely to contain characters not in valid utf-8
task :list_invalid_utf8, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	c = CommonMigrationMethods.new
	c.check_encoding(args[:foxmlfolderpath],args[:outputfilename])
end

#check the elements most likely to contain characters not in valid utf-8
task :list_missing_exam_ds, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	c = CommonMigrationMethods.new
	c.check_has_main(args[:foxmlfolderpath],args[:outputfilename])
end 

end #end of tasks