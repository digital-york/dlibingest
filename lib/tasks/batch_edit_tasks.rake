namespace :batch_edit_tasks do


require_relative '../../app/models/batch_edit.rb'




task :greet do
	puts "doing the greet task"
end



#add (or edit) a  label for a single specified fileset
task :edit_single_fileset_label, [:fsid,:newlabel] => :environment  do|t, args|
	b = BatchEdit.new
	b.edit_single_fileset_label(args[:fsid],args[:newlabel])
end


#add a new label to all the THESIS_ADDITIONAL filesets for a specified range of records 
#task :edit_thesis_additional_labels => :environment do
task :edit_thesis_additional_labels, [:id_list_path] => :environment do|t, args|
	b = BatchEdit.new
	b.edit_thesis_additional_labels(args[:id_list_path])
end



#ok
#try this one instead, which get the theses first and then gets their members
task :edit_thesis_main_labels, [:id_list_path] => :environment do|t, args|
b = BatchEdit.new
	b.add_thesis_main_labels(args[:id_list_path])
end



end #end of tasks