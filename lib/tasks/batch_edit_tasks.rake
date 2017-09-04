namespace :batch_edit_tasks do


require_relative '../../app/models/batch_edit.rb'




task :greet do
	puts "doing the greet task"
end

#add a new label to all the THESIS_MAIN filesets
task :edit_fileset_labels => :environment do
	b = BatchEdit.new
	b.edit_fileset_labels
end

#add (or edit) a  label for a single specified fileset
task :edit_single_fileset_label, [:fsid,:newlabel] => :environment  do|t, args|
	b = BatchEdit.new
	b.edit_single_fileset_label(args[:fsid],args[:newlabel])
end


#add a new label to all the THESIS_ADDITIONAL filesets for a specified range of records (hard code into batch_edit.rb :-( )
#task :edit_thesis_additional_labels => :environment do
task :edit_thesis_additional_labels, [:id_list_path] => :environment do|t, args|
	b = BatchEdit.new
	b.edit_thesis_additional_labels(args[:id_list_path])
end




end #end of tasks