namespace :migration_tasks do


require_relative '../../app/models/foxml_reader.rb'
require_relative '../../app/models/exam_paper_migrator.rb'
require_relative '../../app/models/common_migration_methods.rb'
require_relative '../../app/models/undergraduate_paper_migrator.rb'


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

task :test_undergrads => :environment do
puts "rake task says hi"
	e = UndergraduatePaperMigrator.new
	e.test
end

task :migrate_undergrad_paper, [:path,:serverurl,:collection_mapping,:user] => :environment do|t, args|
puts "doing it.Args were: #{args}"
u = UndergraduatePaperMigrator.new
u.migrate_undergraduate_paper(args[:path],args[:serverurl],args[:collection_mapping],args[:user])
end

task :bulk_migrate_undergrad_papers, [:path_to_fox,:path_to_foxdone,:content_server_url,:collection_mapping,:user] => :environment do|t, args|
puts "doing it.Args were: #{args}"
u = UndergraduatePaperMigrator.new
u.migrate_lots_of_ug_papers(args[:path_to_fox],args[:path_to_foxdone],args[:content_server_url],args[:collection_mapping],args[:user])
end


task :make_thesis_collection_structure, [:mapping_path,:foxpath,:user]  => :environment do|t, args|
puts "Args were: #{args}"
	r = FoxmlReader.new
	r.make_thesis_collection_structure(args[:mapping_path],args[:foxpath],args[:user])
end

task :make_restricted_exam_collection_structure, [:mapping_path,:foxpath,:user]  => :environment do|t, args|
puts "Args were: #{args}"
	e = ExamPaperMigrator.new
	e.make_restricted_exam_collection_structure(args[:mapping_path],args[:foxpath],args[:user])
end

task :make_exam_collection_structure, [:mapping_path,:foxpath,:user]  => :environment do|t, args|
puts "Args were: #{args}"
	e = ExamPaperMigrator.new
	e.make_exam_collection_structure(args[:mapping_path],args[:foxpath],args[:user])
end



task :make_undergraduate_paper_collection_structure, [:mapping_path,:foxpath,:user]  => :environment do|t, args|
puts "Args were: #{args}"
	e = UndergraduatePaperMigrator.new
	e.make_undergraduate_paper_collection_structure(args[:mapping_path],args[:foxpath],args[:user])
end

task :bulk_migrate_undergrad_papers, [:dirpath,:donedirpath,:contentserverurl,:collection_mapping_doc,:user] => :environment  do|t, args|
puts "Args were: #{args}"
r = FoxmlReader.new
r.migrate_lots_of_theses_with_content_url(args[:dirpath],args[:donedirpath],args[:contentserverurl],args[:collection_mapping_doc],args[:user])
end

task :bulk_migrate_theses, [:dirpath,:donedirpath,:contentserverurl,:collection_mapping_doc,:user] => :environment  do|t, args|
puts "Args were: #{args}"
r = FoxmlReader.new
r.migrate_lots_of_theses_with_content_url(args[:dirpath],args[:donedirpath],args[:contentserverurl],args[:collection_mapping_doc],args[:user])
end

task :bulk_migrate_exams, [:dirpath,:donedirpath,:contentpath,:collection_mapping_doc,:user] => :environment  do|t, args|
puts "Args were: #{args}"
e = ExamPaperMigrator.new
e.migrate_lots_of_exams(args[:dirpath],args[:donedirpath],args[:contentpath],args[:collection_mapping_doc],args[:user])
end

task :OLDmigrate_lots_of_theses, [:dirpath,:donedirpath,:contentpath,:collection_mapping_doc,:user] => :environment  do|t, args|
puts "Args were: #{args}"
puts "need to do sommat here"
r = FoxmlReader.new
r.migrate_lots_of_theses(args[:dirpath],args[:donedirpath],args[:contentpath],args[:collection_mapping_doc],args[:user])
end

task :migrate_thesis, [:path,:contentserverurl,:collection_mapping,:user] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate_thesis_with_content_url(args[:path],args[:contentserverurl],args[:collection_mapping],args[:user])
end

task :migrate_thesis_embedded_only, [:path,:contentpath,:collection_mapping,:user] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	r = FoxmlReader.new
	r.migrate_thesis(args[:path],args[:contentpath],args[:collection_mapping],args[:user])
end

task :migrate_exam_paper, [:path,:content_server_url,:collection_mapping,:user] => :environment  do|t, args|
puts "Hi there. Args were: #{args}"
	e = ExamPaperMigrator.new
	e.migrate_exam(args[:path],args[:content_server_url],args[:collection_mapping],args[:user])
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