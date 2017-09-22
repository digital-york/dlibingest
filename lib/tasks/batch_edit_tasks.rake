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

#change thesis group permissions from public to york
#use solr query has_model_ssim:"Thesis" and edits to get list
task :change_thesis_permissions, [:id_list_path] => :environment do|t, args|
	b = BatchEdit.new
	b.change_thesis_permissions(args[:id_list_path])
end

#change collection group permissions from public to york
#use solr query has_model_ssim:"Thesis" and edits to get list
task :change_collection_permissions, [:id_list_path] => :environment do|t, args|
	b = BatchEdit.new
	b.change_collection_permissions(args[:id_list_path])
end

#add additional attributes to existing collections by crossreferencing old fedora objects from mapping file
task :add_attributes_to_collections, [:collection_mapping_path,:foxpath]  => :environment do|t, args|
puts "Args were: #{args}"
	b = BatchEdit.new
	b.add_attributes_to_collections(args[:collection_mapping_path],args[:foxpath])
end


#batch edit to add THESIS_MAIN label where missing
task :edit_thesis_main_labels, [:id_list_path] => :environment do|t, args|
b = BatchEdit.new
	b.add_thesis_main_labels(args[:id_list_path])
end



end #end of tasks