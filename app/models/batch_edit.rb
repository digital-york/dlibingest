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



# bulk deletion task. removes records of a single type, plus their members
#rake batch_edit_tasks:delete_works[/home/dlib/lists/deletelist.txt,ExamPaper]
def delete_works(idlist, worktype)

work_ids = IO.readlines(idlist)
work_ids.each do |i|	
i = i.strip
	record = nil
		if worktype == "Thesis"
			record = Object::Thesis.find(i)
			validtype = true
		elsif worktype == "ExamPaper"
			record = Object::ExamPaper.find(i)
			validtype = true
		else
			puts "unknown worktype"
			validtype = false
		end
		
		if validtype
		#this may need elaboration if filesets include embedded files
		puts "about to start deleting " + i
		puts "proof " + record.title[0]
			filesets = record.members
			filesets.each do |m|
				id = m.id 
				fs = FileSet.find(id)
				fs.delete
			end
			record.delete
		else
			return
		end
	end#end of foreach for work_ids (whole list)
end #end delete_work



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

#change group permissions to public
#use solr query has_model_ssim:Thesis to get list
#rake batch_edit_tasks:change_thesis_permissions[/home/dlib/lists/thesis_list_name.txt]
def change_thesis_permissions(id_list_path)
#work_ids = CSV.parse(id_list_file)
work_ids = IO.readlines(id_list_path) 
   # work_ids = ['s7526c41m', 'qj72p713s']  
	work_ids.each do |i|
	i = i.strip #trailing white space, line ends etc will cause a faulty uri error	
		t = Object::Thesis.find(i)  
		puts "got thesis for " + i		
		t.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
		t.save!
		members = t.members
			members.each do |m|
				id = m.id
				fs = Object::FileSet.find(id)				
		        fs.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
				fs.save!
			end
	end
end

#change group permissions to public
#use solr query has_model_ssim:Thesis to get list
#rake batch_edit_tasks:change_collection_permissions[/home/dlib/lists/col_ids.txt]
def change_collection_permissions(id_list_path)
work_ids = IO.readlines(id_list_path)
	work_ids.each do |i|
	i = i.strip #trailing white space, line ends etc will cause a faulty uri error	
		c = Object::Collection.find(i)  
		puts "got collection for " + i
		c.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
		c.save!		
	end
end

#add more attributes to collections
#we already have a mapping file
#rake batch_edit_tasks:add_attributes_to_collections[/home/dlib/mapping_files/col_mapping_test.txt,/home/dlib/testfiles/foxml/]
def add_attributes_to_collections(collection_mapping_path, foxpath)
mapping_text = File.read(collection_mapping_path)
	csv = CSV.parse(mapping_text)
	csv.each do |item|    
		old_id = item[0]
		new_id = item[2]		
		title = item[1]
		puts "working on " + title
		col = Object::Collection.find(new_id)
		col.former_id = [old_id]
		col = populate_collection(old_id, col, foxpath)
		col.save!
	end
end

#could do with populating collection objects further, although no model mapping avail in google  docs
#in exams i can see creator, description, title,rights,subject, and I think we also need former id
#available attributes:  collections_category: [], former_id: [], publisher: [], rights_holder: [], rights: [], license: [], language: [], language_string: [], keyword: [], description: [], date: [], creator_string: [], title: [], rdfs_label: nil, preflabel: nil, altlabel: [], depositor: nil, date_uploaded: nil, date_modified: nil, head: [], tail: [], publisher_resource_ids: [], subject_resource_ids: [], creator_resource_ids: [], access_control_id: nil, representative_id: nil, thumbnail_id: nil>
#will need to export the full list of foxml objects first, doh
def populate_collection(former_id, collection, foxpath)
# title is already set
#former_id is already set
#creator_string
#description[]
#rights[]
#subject_resource_ids??????? 
#read old collection file
collFileName = former_id.strip
collFileName = collFileName.sub ':', '_'
collFileName = collFileName + ".xml"
path = foxpath + collFileName
doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
# doesnt resolve nested namespaces, this fixes that
ns = doc.collect_namespaces	
# find max dc version (we will only want dc)
nums = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/@ID",ns)	
all = nums.to_s
current = all.rpartition('.').last 
currentVersion = 'DC.' + current
creatorArray = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns).to_s
collection.creator_string = [creatorArray.to_s]
description = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:description/text()",ns).to_s
collection.description = [description]
#subjects (for now)
keywords = []
doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
	keywords.push(s.to_s)
end
defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
#fr = FoxmlReader.new
common = CommonMigrationMethods.new
coll_rights = defaultLicence
coll_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
newrights =  common.get_standard_rights(coll_rights)#  all theses currently York restricted 	
if newrights.length > 0
	coll_rights = newrights	
end	
collection.rights=[coll_rights]
return collection
end  #end of populate_collection method


# add  label to individual fileset (could also be used to change an existing one)
#rake batch_edit_tasks:edit_single_fileset_label[id,label]
def edit_single_fileset_label(fsid, labelname)
	fs = Object::FileSet.find(fsid)
				fs.label = labelname
				fs.save!
end

#rake batch_edit_tasks:add_former_pids_from_file
def add_former_pids_from_file
former_pids_added = File.open("formerpidsadded.txt", "a")
failedfile = File.open("formerpidfails.txt", "a")
matchtext = File.read("/home/dlib/lists/pid-id_mappings.txt")
csv = CSV.parse(matchtext)
csv.each do |line|    
		old_pid = line[0].to_s
		new_id = line[1].to_s				
		thesis = Object::Thesis.find(new_id)
		thesis.former_id = [old_pid]
		if thesis.save! 
			former_pids_added.puts "added former id " + old_pid + " to thesis " +  new_id  
		else
			failedfile.puts "failed to add former id " + old_pid + " to " + new_id
		end
end
former_pids_added.close
failedfile.close
end #end of add__former_ids_from_file

#[/home/dlib/mapping_files/col_mapping_test.txt,/home/dlib/testfiles/foxml/]
#rake batch_edit_tasks:add_former_pids[/home/dlib/lists/pid_title.txt,/home/dlib/lists/id_title.txt]
def add_former_pids(pid_list_path, id_list_path)

trackingfile = File.open("pidtracking.txt", "a")
nomatchfile = File.open("matchfails.txt", "a")
old_list = {}
new_list = {}
#the old fedora list
puts "pid list file is " + pid_list_path
puts "id list file is " + id_list_path
pid_text = File.read(pid_list_path,)
#pid_text = File.read(pid_list_path, Encoding::UTF_8)
csv = CSV.parse(pid_text)
csv.each do |line| 
	the_pid = line[0].strip
	the_title = line[1]	.strip	
	old_list[the_pid] = the_title
end

id_text = File.read(id_list_path)
csv2 = CSV.parse(id_text)
csv2.each do |line| 
	the_id = line[0].strip
	the_title = line[1].strip
	new_list[the_id] = the_title
end


#iterate through the keys (ids) in the new list
	new_list.each do |id, title|
		the_title = title
		match = old_list.key(the_title)
		if match != nil 
			thesis = Object::Thesis.find(id)
			thesis.former_id = [match]
			thesis.save!
			trackingfile.puts "found former id " + match + " to thesis " +  id  
		else
			puts "no match"
			nomatchfile.puts "could not match title for " + id + " unmatched title was " + the_title
		end
	end
trackingfile.close
nomatchfile.close
end  #end of add_former_id



end # end of class