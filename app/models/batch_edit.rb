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




# add  label to  THESIS_MAIN filesets for a specified range of theses
#using this in preference as should exclude unwanted 'orphan' filesets created as tests etc
#rake batch_edit_tasks:edit_thesis_main_labels[/home/dlib/testfiles/id_listtest.txt]
def add_thesis_main_labels(id_list_path)
#work_ids = CSV.parse(id_list_file)
work_ids = IO.readlines(id_list_path)  
	work_ids.each do |i|
	i = i.strip #trailing white space, line ends etc will cause a faulty uri error	
		t = Object::Thesis.find(i)  
		puts "got thesis for " + i
		thesis_title = t.title[0]
		puts "thesis_title was " + thesis_title
		members = t.members
			members.each do |m|
				id = m.id
				fs = Object::FileSet.find(id)
				title = fs.title[0]
				if title.start_with?('THESIS_MAIN') 
					if fs.label != "THESIS_MAIN"
						fs.label = "THESIS_MAIN"
						fs.save!
					end
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
#rake batch_edit_tasks:edit_single_fileset_label[id,label]
def edit_single_fileset_label(fsid, labelname)
	fs = Object::FileSet.find(fsid)
				fs.label = labelname
				fs.save!
end





end # end of class