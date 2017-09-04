# encoding: UTF-8
#require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'


# methods to create the  collection structure and do migrations
class BatchEdit
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra


# add  label to existing THESIS_MAIN filesets   TESTED ON MEGASTACK
#rake batch_edit_tasks:edit_fileset_labels
def edit_fileset_labels
	filesets = Object::FileSet.all
	filesets.each do |fs| 
	title = fs.title[0]
	#if label is empty and title = THESIS_MAIN
	#test label first to avoid wasting time on the big archaeology set
		if fs.label == nil
			if title == "THESIS_MAIN"
				fs.label = title
				fs.save!
			end
		end
	end
end

# add  label to  THESIS_ADDITIONALxx filesets for a specified range
#rake batch_edit_tasks:edit_thesis_additional_labels
#just have to populate in the script when ready - cant see an easy way to pass in
#def edit_thesis_additional_labels
def edit_thesis_additional_labels(id_list_path)
#work_ids = CSV.parse(id_list_file)
work_ids = IO.readlines(id_list_path) 
   # work_ids = ['s7526c41m', 'qj72p713s']  
	work_ids.each do |i|
	i = i.strip #trailing white space, line ends etc will cause a faulty uri error	
		t = Object::Thesis.find(i)  
		puts "got thesis for " + i
		members = t.members
			members.each do |m|
				id = m.id
				fs = Object::FileSet.find(id)
				title = fs.title[0]
				if title.start_with?('THESIS_ADDITIONAL') 
					fs.label = "THESIS_ADDITIONAL"
					fs.save!
				end
			end
	end
end

# add  label to individual fileset (could also be used to change an existing one)
#rake batch_edit_tasks:edit_fileset_labels
def edit_single_fileset_label(fsid, labelname)
	fs = Object::FileSet.find(fsid)
				fs.label = labelname
				fs.save!
end


end # end of class