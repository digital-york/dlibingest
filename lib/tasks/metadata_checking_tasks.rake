namespace :metadata_checking_tasks do


require_relative '../../app/helpers/migration/date_manipulation.rb'
require_relative '../../app/helpers/migration/metadata_checks.rb'


task :greet do
	puts "greetings from the test tasks"
end

##################UTILITY TASKS - useful for checks prior to migrations##################

#test the date normalisation
task :check_date_normalisation, [:input_file_path,:output_file_path]  => :environment do|t, args|
puts "Args were: #{args}"
	d = DateManipulation.new
	d.run_normalisation_check(args[:input_file_path],args[:output_file_path])
end



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