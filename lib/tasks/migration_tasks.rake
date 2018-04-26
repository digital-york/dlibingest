namespace :migration_tasks do



require_relative '../../app/helpers/migration/thesis_migrator.rb'
require_relative '../../app/helpers/migration/exam_paper_migrator.rb'
require_relative '../../app/helpers/migration/common_migration_methods.rb'
require_relative '../../app/helpers/migration/undergraduate_paper_migrator.rb'
require_relative '../../app/helpers/migration/thesis_collection_migrator.rb'
require_relative '../../app/helpers/migration/exam_paper_collection_migrator.rb'
require_relative '../../app/helpers/migration/metadata_checks.rb'


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

#calls a thesis test method, definable in thesis_migrator
task :test_theses => :environment do
	t = ThesisMigrator.new
	t.test
end

task :test_undergrads => :environment do
puts "rake task says hi"
	e = UndergraduatePaperMigrator.new
	e.test
end

########### THESES TASKS ##############

task :make_thesis_collection_structure, [:mapping_path,:foxpath,:user]  => :environment do|t, args|
puts "Args were: #{args}"
	tc = ThesisCollectionMigrator.new
	tc.make_thesis_collection_structure(args[:mapping_path],args[:foxpath],args[:user])
end

task :bulk_migrate_theses, [:dirpath,:donedirpath,:contentserverurl,:user] => :environment  do|t, args|
puts "Args were: #{args}"
t = ThesisMigrator.new
t.bulk_migrate_theses_with_content_url(args[:dirpath],args[:donedirpath],args[:contentserverurl],args[:user])
end

task :migrate_thesis, [:path,:contentserverurl,:user] => :environment  do|t, args|
puts "Args were: #{args}"
puts "hey there"
	t = ThesisMigrator.new	
	t.migrate_thesis_with_content_url(args[:path],args[:contentserverurl],args[:user])
end

########### EXAMS TASKS ##############

task :make_restricted_exam_collection_structure, [:mapping_path,:foxpath,:user]  => :environment do|t, args|
puts "Args were: #{args}"
	e = ExamPaperCollectionMigrator.new
	e.make_restricted_exam_collection_structure(args[:mapping_path],args[:foxpath],args[:user])
end

task :make_exam_collection_structure, [:mapping_path,:foxpath,:user]  => :environment do|t, args|
puts "Args were: #{args}"
	e = ExamPaperCollectionMigrator.new
	e.make_exam_collection_structure(args[:mapping_path],args[:foxpath],args[:user])
end

task :bulk_migrate_exams, [:dirpath,:donedirpath,:contentpath,:outputs_dir,:user] => :environment  do|t, args|
puts "Args were: #{args}"
e = ExamPaperMigrator.new
e.batch_migrate_exams(args[:dirpath],args[:donedirpath],args[:contentpath],args[:outputs_dir],args[:user])
end

task :migrate_exam_paper, [:path,:content_server_url,:outputs_dir,:user] => :environment  do|t, args|
puts "Hi there. Args were: #{args}"
	e = ExamPaperMigrator.new	
	e.migrate_exam(args[:path],args[:content_server_url],args[:outputs_dir],args[:user])
end


########### UNDERGRADUATE PAPER TASKS ##############

task :make_undergraduate_paper_collection_structure, [:mapping_path,:foxpath,:user]  => :environment do|t, args|
puts "Args were: #{args}"
	u = UndergraduatePaperCollectionMigrator.new
	u.make_undergraduate_paper_collection_structure(args[:mapping_path],args[:foxpath],args[:user])
end

task :bulk_migrate_undergrad_papers, [:path_to_fox,:path_to_foxdone,:content_server_url,:collection_mapping,:user] => :environment do|t, args|
puts "doing it.Args were: #{args}"
u = UndergraduatePaperMigrator.new
u.migrate_lots_of_ug_papers(args[:path_to_fox],args[:path_to_foxdone],args[:content_server_url],args[:collection_mapping],args[:user])
end

task :migrate_undergrad_paper, [:path,:serverurl,:collection_mapping,:user] => :environment do|t, args|
puts "doing it.Args were: #{args}"
u = UndergraduatePaperMigrator.new
u.migrate_undergraduate_paper(args[:path],args[:serverurl],args[:collection_mapping],args[:user])
end



##################UTILITY TASKS - useful for checks prior to migrations~~~~~~~~~~~~~ 

#write list of every datastream in a folder of objects
task :list_datastreams, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	mc = MetadataChecks.new
	mc.list_all_ds_in_set(args[:foxmlfolderpath],args[:outputfilename])
end

#write list of every variant datastream label in a folder of objects
task :list_datastream_labels, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	mc = MetadataChecks.new
	mc.list_all_labels_in_set(args[:foxmlfolderpath],args[:outputfilename])
end

#check for format values to see if any non pdf
task :list_format_values, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	mc = MetadataChecks.new
	mc.check_format_values(args[:foxmlfolderpath],args[:outputfilename])
end

task :list_dc_creator_values, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	mc = MetadataChecks.new
	mc.list_dc_creator_values(args[:foxmlfolderpath],args[:outputfilename])
end

task :list_dc_type_values, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	mc = MetadataChecks.new
	mc.list_dc_type_values(args[:foxmlfolderpath],args[:outputfilename])
end

#check the elements most likely to contain characters not in valid utf-8
task :list_invalid_utf8, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	mc = MetadataChecks.new
	mc.check_encoding(args[:foxmlfolderpath],args[:outputfilename])
end

#check the elements most likely to contain characters not in valid utf-8
task :list_missing_exam_ds, [:foxmlfolderpath,:outputfilename] => :environment do|t, args|
puts "Args were: #{args}"
	mc = MetadataChecks.new
	mc.check_has_main(args[:foxmlfolderpath],args[:outputfilename])
end 

end #end of tasks