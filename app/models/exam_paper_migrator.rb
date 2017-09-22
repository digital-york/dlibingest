# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# methods to create the  collection structure and do Exam Paper migrations
class ExamPaperMigrator
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra


=begin
we need to check if the collection structure here is similar to that for theses
*the list of possible collections under theses is quite extensive - get it from  risearch querys, then find and replace to format
*format is: old pid of collection,title of collection,old parent_pid
NO: PHYSICS HAS AN ODD STRUCTURE. A 4th layer 
top level is york:21267 title is Exam Papers
second level listfile is  exam_colls_level2.txt
third level listfiles is exam_colls_level3.txt
fourth level (physics) listfiles is exam_colls_level4_physics.txt
*exam_col_mapping.txt is output by the script and is the permanent mapping file. format:
originalpid, title, newid . 
made the path to the various files used for this a parameter 
on dev server use "/home/dlib/mapping_files/"  (with end slash)
so call is like rake migration_tasks:make_exam_collection_structure[/home/dlib/mapping_files/,/home/dlib/testfiles/foxml/].
This works , but more infor needed in collections. could get this by writing a little method which can be called when creating each object to populate it. will obviously take longer to process but can be reused without rewriting for every collection.

=end
#mapping_path is path to the mapping file, foxpath is the path to the existing foxml collection files 
def make_exam_collection_structure(mapping_path, foxpath)
puts "running make_exam_collection_structure"
mapping_file = mapping_path +"exam_col_mapping.txt"
# make the top Exams level first, with a CurationConcerns (not dlibhydra) model.
#array of lines including title
topmapping = []
# we also need a pid:id hash so we can extract id via a pid key
idmap ={}
toppid = "york:21267"    #top level collection
topcol = Object::Collection.new
topcol.title = ["Exam papers"]
topcol.former_id = [toppid]
topcol = populate_collection(toppid, topcol, foxpath)  
topcol.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
topcol.depositor = "ps552@york.ac.uk"
topcol.save!
topcol_id = topcol.id.to_s
puts "topcol.id was " +topcol.id
mappings_string = toppid + "," + topcol.title[0].to_s + "," + topcol_id 
topmapping.push(mappings_string) 
# add to hash, old pid as key, new id as value
	key = toppid	
	idmap[key] = topcol.id
# write to file as  permanent mapping that we can use when mapping theses against collections 
open(mapping_file, "a+")do |mapfile|
mapfile.puts(topmapping)
end

=begin
now we need to read from the list which I will create, splitting into appropriate parts and for each create an id and add it to the top level collection
=end
# hardcode second level file, but could pass in as param
level2file = mapping_path + "exam_colls_level2.txt"
csv_text = File.read(level2file)
csv = CSV.parse(csv_text)
# we also need a file we can write to, as a permanent mapping
mappings_level2 = []

puts "starting second level(subjects)"
csv.each do |line|
    puts line[0]
	col = Object::Collection.new
	# col = Dlibhydra::Collection.new
	col.title = [line[1]]
	col.former_id = [line[0].strip]
	col = populate_collection(line[0].strip, col, foxpath) 
	col.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	col.depositor = "ps552@york.ac.uk"
	col.save!
	col_id = col.id.to_s
	puts "subject col id was" + col_id
	topcol.members << col
	topcol.save!
	mappings_string = line[0] + "," + line[1] + "," + col_id 
	mappings_level2.push(mappings_string)
	# add to hash, old pid as key, new id as value
	key = line[0]	
	idmap[key] = col.id
end

# write to file as  permanent mapping that we can use when mapping theses against collections
open(mapping_file, "a+")do |mapfile| 
	mapfile.puts(mappings_level2)
end

# but we still have our mappings array, so  now use this to make third level collections
sleep 5 # wait 5 seconds before moving on to allow 2nd level collections some time to index before the level3s start trying to find them

# read in third level file
mappings_level3 = []
level3collsfile = mapping_path + "exam_colls_level3.txt"
csv_text3 = File.read(level3collsfile)
csv_level3 = CSV.parse(csv_text3)
yearpidcount = 1
puts "starting third level (years)"
csv_level3.each do |line|
yearpidcount = yearpidcount +1
    puts "starting number " +yearpidcount.to_s+ " in list"
    puts line[0]
	year_col = Object::Collection.new
	puts "started new year collection"
	# col = Dlibhydra::Collection.new extend cc collection instead
	year_col_title = line[1].to_s
	puts "got level 3 title which was " +year_col_title
	year_col.title =  [year_col_title]
	year_col.former_id = [line[0].strip]
	year_col = populate_collection(line[0].strip, year_col, foxpath)
	year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	year_col.depositor = "ps552@york.ac.uk"
	year_col.save!
	year_col_id = year_col.id.to_s
	# need to find the right parent collection here	
	parent_pid = line[2]# old parent pid, key to find new parent id
	mapped_parent_id = idmap[parent_pid]	
	parent = Object::Collection.find(mapped_parent_id)
	parent.members << year_col
	parent.save!
	mappings_string = line[0] + "," + line[1] + "," + year_col_id 
	mappings_level3.push(mappings_string)
	# add to hash, old pid as key, new id as value
	key = line[0].strip	
	idmap[key] = year_col.id
end
# and write to permanent mapping file - these can be all the same file whatever level
open(mapping_file, "a+")do |mapfile|
	mapfile.puts(mappings_level3)
end

# level 4
sleep 5 # wait 5 seconds before moving on to allow 2nd level collections some time to index before the level3s start trying to find them
mappings_level4 = []
level4collsfile = mapping_path + "exam_colls_level4_physics.txt"
csv_text4 = File.read(level4collsfile)
csv_level4 = CSV.parse(csv_text4) 
yearpidcount = 1
puts "starting fourth level (physics years)"
csv_level4.each do |line|
yearpidcount = yearpidcount +1
    puts "starting number " +yearpidcount.to_s+ " in list"
    puts line[0]
	physics_year_col = Object::Collection.new
	puts "started new physics year collection"
	# col = Dlibhydra::Collection.new extend cc collection instead
	year_col_title = line[1].to_s
	puts "got level 4 title which was " +year_col_title
	physics_year_col.title =  [year_col_title]
	physics_year_col.former_id = [line[0].strip]
	physics_year_col = populate_collection(line[0].strip, physics_year_col, foxpath)  #KALE
	physics_year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	physics_year_col.depositor = "ps552@york.ac.uk"
	physics_year_col.save!
	physics_year_col_id = physics_year_col.id.to_s
	# need to find the right parent collection here	
	parent_pid = line[2]# old parent pid, key to find new parent id
	mapped_parent_id = idmap[parent_pid]	
	parent = Object::Collection.find(mapped_parent_id)
	parent.members << physics_year_col
	parent.save!
	mappings_string = line[0] + ","   + line[1] + "," + physics_year_col.id 
	mappings_level4.push(mappings_string)
end
# write to permanent mapping file - these can be all the same file whatever level
open(mapping_file, "a+")do |mapfile|
	mapfile.puts(mappings_level4)
end
#end of level 4


puts "all collections done"

end  # of make collection structure method

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
coll_rights = defaultLicence
coll_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
common = CommonMigrationMethods
newrights = common.get_standard_rights(coll_rights)#  all theses currently York restricted 	
if newrights.length > 0
	coll_rights = newrights	
end	
collection.rights=[coll_rights]
return collection
end  #end of populate_collection method




# MEGASTACK rake migration_tasks:migrate_lots_of_theses_with_content_url[/home/ubuntu/testfiles/foxml,/home/ubuntu/testfiles/foxdone,/home/ubuntu/mapping_files/col_mapping.txt]
# devserver rake migration_tasks:migrate_lots_of_theses_with_content_url[/home/dlib/testfiles/foxml,/home/dlib/testfiles/foxdone,https://dlib.york.ac.uk,/home/dlib/mapping_files/col_mapping.txt]
def migrate_lots_of_exams_with_content_url(path_to_fox, path_to_foxdone, content_server_url, collection_mapping_doc_path)
puts "doing a bulk migration"
fname = "tally.txt"
tallyfile = File.open(fname, "a")
Dir.foreach(path_to_fox)do |item|	
	# we dont want to try and act on the current and parent directories
	next if item == '.' or item == '..'
	# trackingfile.puts("now working on " + item)
	itempath = path_to_fox + "/" + item
	result = 2  # so this wont do the actions required if it isnt reset
	begin
		result = migrate_thesis_with_content_url(itempath,content_server_url,collection_mapping_doc_path)
	rescue
		result = 1	
		tallyfile.puts("rescue says FAILED TO INGEST "+ itempath)  
	end
	if result == 0
		tallyfile.puts("ingested " + itempath)
		#sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
		FileUtils.mv(itempath, path_to_foxdone + "/" + item)  # move files once migrated
	elsif result == 1   # this may well not work, as it may stop part way through before it ever gets here. rescue block might help?
		tallyfile.puts("FAILED TO INGEST "+ itempath)
		sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
	else
        tallyfile.puts(" didnt return expected value of 0 or 1 ")	
	end
end
tallyfile.close
puts "all done"
end # end migrate_lots_of_theses_with_content_url



#version of migration that adds the content file url but does not ingest the content pdf into the thesis
# on megastack: # rake migration_tasks:migrate_thesis_with_content_url[/home/ubuntu/testfiles/foxml/york_xxxxx.xml,/home/ubuntu/mapping_files/col_mapping.txt]
# new signature: # rake migration_tasks:migrate_thesis_with_content_url[/home/dlib/testfiles/foxml/mytest.xml,https://dlib.york.ac.uk,/home/dlib/mapping_files/col_mapping.txt]
def migrate_exam_with_content_url(path, content_server_url, collection_mapping_doc_path) 
result = 1 # default is fail
mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . (app one is not namespaced)

puts "migrating a thesis with content url"	
	foxmlpath = path	
	# enforce  UTF-8 compliance when opening foxml file
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
	# doesnt resolve nested namespaces, this fixes that
    ns = doc.collect_namespaces	
	
	# establish parent collection - map old to new from mappings file
	collection_mappings = {}
	mapping_text = File.read(collection_mapping_doc_path)
	csv = CSV.parse(mapping_text)
	csv.each do |line|    
		old_id = line[0]
		new_id = line[2]		
		collection_mappings[old_id] = new_id
	end
	
	# make sure we have current rels-ext version
	rels_nums = doc.xpath("//foxml:datastream[@ID='RELS-EXT']/foxml:datastreamVersion/@ID",ns)	
	rels_all = all = rels_nums.to_s
	current_rels = rels_all.rpartition('.').last 
	rels_current_version = 'RELS-EXT.' + current_rels
	untrimmed_former_parent_pid  = doc.xpath("//foxml:datastream[@ID='RELS-EXT']/foxml:datastreamVersion[@ID='#{rels_current_version}']/foxml:xmlContent/rdf:RDF/rdf:Description/rel:isMemberOf/@rdf:resource",ns).to_s	
	# remove unwanted bits 
	former_parent_pid = untrimmed_former_parent_pid.sub 'york', 'york'
	parentcol = collection_mappings[former_parent_pid]
	# find max dc version
	nums = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/@ID",ns)	
	all = nums.to_s
	current = all.rpartition('.').last 
	currentVersion = 'DC.' + current
	
	# find the max THESIS_MAIN version
	thesis_nums = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion/@ID",ns)	
	thesis_all = thesis_nums.to_s
	thesis_current = thesis_all.rpartition('.').last 
	currentThesisVersion = 'THESIS_MAIN.' + thesis_current
	# GET CONTENT - get the location of the pdf as a string
	pdf_loc = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion[@ID='#{currentThesisVersion}']/foxml:contentLocation/@REF",ns).to_s	
	
	# CONTENT FILES
	# this has local.fedora.host, which will be wrong. need to replace this with whereever they will be sitting 
	# reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	# needs to read (for development purposes on real machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	# newpdfloc = pdf_loc.sub 'local.fedora.server', 'yodlapp3.york.ac.uk'  # CHOSS we dont need this any more as we cant download remotely
	#and the content_server_url is set in the parameters :-)
	externalpdfurl = pdf_loc.sub 'http://local.fedora.server', content_server_url #this will be added to below. once we have external urls can add in relevant url
    externalpdflabel = "THESIS_MAIN"  #default
	# label needed for gui display
			label = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion[@ID='#{currentThesisVersion}']/@LABEL",ns).to_s 
			if label.length > 0
			externalpdflabel = label #in all cases I can think of this will be the same as the default, but just to be sure
			end
	
# hash for any THESIS_ADDITIONAL URLs. needs to be done here rather than later to ensure we obtain overridden version og FileSet class rather than CC as local version not namespaced
    additional_filesets = {}	
	elems = doc.xpath("//foxml:datastream[@ID]",ns)
	elems.each { |id| 
		idname = id.attr('ID')		
		if idname.start_with?('THESIS_ADDITIONAL')
	#ok, now need to find the latest version 
			version_nums = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion/@ID",ns)
			current_version_num = version_nums.to_s.rpartition('.').last
			current_version_name = idname + '.' + current_version_num
			addit_file_loc = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/foxml:contentLocation/@REF",ns).to_s
			addit_file_loc = addit_file_loc.sub 'http://local.fedora.server', content_server_url
			fileset = Object::FileSet.new
			fileset.filetype = 'externalurl'
			fileset.external_file_url = addit_file_loc
			fileset.title = [idname]
			# may have a label - needed for display-  that is different to the datastream title
			label = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/@LABEL",ns).to_s 
			if label.length > 0
			fileset.label = label
			end
			fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
			fileset.depositor = "ps552@york.ac.uk"
			additional_filesets[idname] = fileset
		end
	}
	
	#also look for ORIGINAL_RESOURCE
	elems = doc.xpath("//foxml:datastream[@ID]",ns)
	elems.each { |id| 
		idname = id.attr('ID')		
		if idname.start_with?('ORIGINAL_RESOURCE')
		
	#ok, now need to find the latest version 
			version_nums = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion/@ID",ns)
			current_version_num = version_nums.to_s.rpartition('.').last
			current_version_name = idname + '.' + current_version_num
			addit_file_loc = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/foxml:contentLocation/@REF",ns).to_s
			addit_file_loc = addit_file_loc.sub 'http://local.fedora.server', content_server_url
			fileset = Object::FileSet.new
			fileset.filetype = 'externalurl'
			fileset.external_file_url = addit_file_loc
			fileset.title = [idname]
			# may have a label - needed for display-  that is different to the datastream title
			label = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/@LABEL",ns).to_s 
			if label.length > 0
			fileset.label = label
			end
			fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
			fileset.depositor = "ps552@york.ac.uk"
			additional_filesets[idname] = fileset
		end
	}
		
	# create a new thesis implementing the dlibhydra models
	thesis = Object::Thesis.new
# trying to set the state but this doesnt seem to be the way - the format  #<ActiveTriples::Resource:0x3fbe8df94fa8(#<ActiveTriples::Resource:0x007f7d1bf29f50>)> obviuously referenes something in a dunamic away
# which is different for each object
=begin
	existing_state = "didnt find an active state" 
	existing_state = doc.xpath("//foxml:objectProperties/foxml:property[@NAME='fedora-system:def/model#state']/@VALUE",ns)
	if existing_state.to_s == "Active"
	#pasted in from gui produced Thesis! not sure if required
	 thesis.state = "http://fedora.info/definitions/1/0/access/ObjState#active"  
	end
=end
	# once depositor and permissions defined, object can be saved at any time
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	thesis.depositor = "ps552@york.ac.uk"
	
	# start reading and populating  data
	titleArray =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	t = titleArray.to_s
		
	thesis.title = [t]	# 1 only	
	# thesis.preflabel =  thesis.title[0] # skos preferred lexical label (which in this case is same as the title. 1 0nly but can be at same time as title 
	former_id = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:identifier/text()",ns).to_s
	if former_id.length > 0
	thesis.former_id = [former_id]
	end
	# could really do with a file to list what its starting work on as a cleanup tool. doesnt matter if it doesnt get this far as there wont be anything to clean up
	tname = "tracking.txt"
	trackingfile = File.open(tname, "a")
	trackingfile.puts( "am now working on " + former_id + " title:" + t )
	trackingfile.close	
	 creatorArray = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns).to_s
	 thesis.creator_string = [creatorArray.to_s]
	
	# abstract is currently the description. optional field so test presence
	thesis_abstract = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:description/text()",ns).to_s
	if thesis_abstract.length > 0
	thesis.abstract = [thesis_abstract] # now multivalued
	end
	
	# date_of_award (dateAccepted in the dc created by the model) 1 only
	thesis_date = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:date/text()",ns).to_s
	thesis.date_of_award = thesis_date
	# advisor 0... 1 so check if present
	thesis_advisor = []
	   doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:contributor/text()",ns).each do |i|
		thesis_advisor.push(i.to_s)
	end
	thesis_advisor.each do |c|
		thesis.advisor_string.push(c)
	end	
   # departments and institutions 
   locations = []
	 doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:publisher/text()",ns).each  do |i|
	 locations.push(i.to_s)
	 end
	 inst_preflabels = []
	 locations.each do |loc|
		# awarding institution id (just check preflabel here as few options)
		if loc.include? "University of York"
			inst_preflabels.push("University of York")
		elsif loc.include? "York." 
			inst_preflabels.push("University of York")
		elsif loc.include? "York:"
			inst_preflabels.push("University of York")
		elsif loc.include? "Oxford Brookes University"
			inst_preflabels.push("Oxford Brookes University") #I'v just added this as a minority of our theses come from here!
		end
		inst_preflabels.each do | preflabel|
			id = get_resource_id('institution', preflabel)
			thesis.awarding_institution_resource_ids+=[id]
		end
				
		# department
		dept_preflabels = get_department_preflabel(loc)		 
		if dept_preflabels.empty?
			puts "no department found"
		end
		dept_preflabels.each do | preflabel|
			id = get_resource_id('department', preflabel)
			thesis.department_resource_ids +=[id]
		end
	end
	
	
	# qualification level, name, resource type
	typesToParse = []  #
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns).each do |t|	
	typesToParse.push(t)
	end
	# qualification names (object)
	qualification_name_preflabel = get_qualification_name_preflabel(typesToParse)
	if qualification_name_preflabel != "unfound"   
		qname_id = get_resource_id('qualification_name',qualification_name_preflabel)
		if qname_id.to_s != "unfound"		
			thesis.qualification_name_resource_ids+=[qname_id]
		else
			puts "no qualification nameid found"
		end
	else
		puts "no qualification name preflabel found"
	end	
	# qualification levels (yml file). there can only be one
	typesToParse.each do |t|	
	type_to_test = t.to_s
	degree_level = get_qualification_level_term(type_to_test)
	if degree_level != "unfound"
		thesis.qualification_level += [degree_level]
	end

	# now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
	# resource Types map to dc:subject. at present the only official value is Dissertations, Academic
	theses = [ 'theses','Theses','Dissertations','dissertations' ] 
	if theses.include? type_to_test	
	# not using methods below yet - or are we? subjects[] no longer in model
		subject_id = get_resource_id('subject',"Dissertations, Academic")
		thesis.subject_resource_ids +=[subject_id]		 
	end
end	
	thesis_language = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:language/text()",ns).each do |lan|
	thesis_language.push(lan.to_s)
	end
	# this should return the key as that allows us to just search on the term
	thesis_language.each do |lan|   #0 ..n
	standard_language = "unfound"
	    standard_language = get_standard_language(lan.titleize)#capitalise first letter
		if standard_language!= "unfound"
			thesis.language+=[standard_language]
		end
	end	
	
	# dc.keyword (formerly subject, as existing ones from migration are free text not lookup
	thesis_subject = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
	thesis_subject.push(s.to_s)
	end
	thesis_subject.each do |s|
		thesis.keyword+=[s]   #TODO::THIS WAS ADDED TO FEDORA AS DC.RELATION NOT DC(OR DC11).SUBJECT!!!
	end	
	# dc11.subject??? not required for migration - see above
		
	# rights.	
	# rights holder 0...1
	# checked data on dlib. all have the same rights statement and url cited, so this should work fine, as everything else is rights holders   
   thesis_rightsholder = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[not(contains(.,'http')) and not (contains(.,'licenses')) ]",ns).to_s
   if thesis_rightsholder.length > 0
	thesis.rights_holder=[thesis_rightsholder] 
   end

	# license  set a default which will be overwritten if one is found. its the url, not the statement. use licenses.yml not rights_statement.yml
	# For full york list see https://dlib.york.ac.uk/yodl/app/home/licences. edit in rights.yml
	defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
	thesis_rights = defaultLicence
	thesis_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
	
	newrights =  get_standard_rights(thesis_rights)#  all theses currently York restricted 	
		if newrights.length > 0
		thesis_rights = newrights
			thesis.rights=[thesis_rights]			
		end	
		
	
	# save	
	thesis.save!
	id = thesis.id
	puts "thesis id was " +id 
	# put in collection	
	col = Object::Collection.find(parentcol.to_s)	
	puts "id of col was:" +col.id
	puts " collection title was " + col.title[0].to_s
	col.members << thesis  
	col.save!
	
	# this is the section that keeps failing
	users = Object::User.all #otherwise it will use one of the included modules
	user = users[0]
	begin
		# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
		mfset.filetype = 'externalurl'
		mfset.title = ["THESIS_MAIN"]	#needs to be same label as content file in foxml 
		mfset.label = externalpdflabel
		# add the external content URL
		mfset.external_file_url = externalpdfurl
		actor = CurationConcerns::Actors::FileSetActor.new(mfset, user)
		actor.create_metadata(thesis)
		#Declare file as external resource
        Hydra::Works::AddExternalFileToFileSet.call(mfset, externalpdfurl, 'external_url')
		mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
		mfset.depositor = "ps552@york.ac.uk"
		mfset.save!
		puts "fileset " + mfset.id + " saved"
    
	  # CHOSS this is here because the system tended to lock up during multiple uploads - suspect competition for resources or threading issue somewhere
		sleep 20 		
		 thesis.mainfile << mfset
		sleep 20  
		 thesis.save!
	rescue
	    puts "QUACK QUACK OOPS! addition of external file unsuccesful"
		result = 1
		return result
		
   end   
     puts "all done for external content mainfile " + id  


# process external THESIS_ADDITIONAL files
for key in additional_filesets.keys() do		
		additional_thesis_file_fs = additional_filesets[key]		
		#add metadata to make fileset appear as a child of the object
        actor = CurationConcerns::Actors::FileSetActor.new(additional_thesis_file_fs, user)
        actor.create_metadata(thesis)
		#Declare file as external resource
		url = additional_thesis_file_fs.external_file_url
        Hydra::Works::AddExternalFileToFileSet.call(additional_thesis_file_fs, url, 'external_url')
        additional_thesis_file_fs.save!
		thesis.members << additional_thesis_file_fs
        thesis.save!
		puts "all done for  additional file " + key
end
	#when done, explicity reset big things to empty to ensure resources not hung on to
	additional_filesets = {} 
    doc = nil
	mapping_text = nil
	collection_mappings = {}	
   result = 0 #this needs to happen last
   return result   # give it  a return value
end # end of migrate_thesis_with_content_url

end # end of class
