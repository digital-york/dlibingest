# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# some methods to create the  collection structure and do migrations
class UndergraduatePaperMigrator
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra

#check its at least valid ruby
def test
puts "Hodor! Hodor!"
end


# make depositor username and password into parameters
=begin
*format is: old pid of collection,title of collection,old parent_pid
*col_mapping.txt is output by the script and is the permanent mapping file. format:
originalpid, title, newid 
*just three layers deep
so call is like rake migration_tasks:make_undergraduate_paper_collection_structure[/home/dlib/mapping_files/tests/,/home/dlib/testfiles/foxml/UG_Collections/test/,user]
=end
def make_undergraduate_paper_collection_structure(mapping_path, foxpath, user)
puts "running make_collection_structure"
mapping_file = mapping_path +"ug_col_mapping.txt"
# make the top Theses level first, with a CurationConcerns (not dlibhydra) model.
#array of lines including title
topmapping = []
# we also need a pid:id hash so we can extract id via a pid key
idmap ={}
toppid = "york:808102"    #top level collection
topcol = Object::Collection.new
topcol.title = ["Undergraduate essays and projects"]
topcol.former_id = [toppid]
topcol = populate_collection(toppid, topcol, foxpath)  
#the top collection is visible to the general public but not the underlying records or collections
topcol.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
topcol.depositor = user
topcol.save!
topcol_id = topcol.id.to_s
puts "topcol.id was " +topcol.id
mappings_string = toppid + "," +  + topcol.title[0].to_s + "," + topcol_id 
	topmapping.push(mappings_string) 
# write to file as  permanent mapping that we can use when mapping theses against collections 
# open("/vagrant/files_to_test/col_mapping.txt", "a+")do |mapfile|
open(mapping_file, "a+")do |mapfile|
mapfile.puts(topmapping)
end

=begin
now we need to read from the list which I will create, splitting into appropriate parts and for each create an id and add it to the top level collection
=end
# hardcode second level file, but could pass in as param
# csv_text = File.read("/vagrant/files_to_test/thesescollectionsLevel2SMALL.txt")
level2file = mapping_path + "UGpaperCollsLevel2.txt"
csv_text = File.read(level2file)
# csv_text = File.read("/vagrant/files_to_test/thesescollectionsLevel2.txt")
csv = CSV.parse(csv_text)
# we also need a file we can write to, as a permanent mapping
mappings_level2 = []

puts "starting second level(subjects)"
csv.each do |line|
    puts line[0]
	col = Object::Collection.new
	# col = Dlibhydra::Collection.new
	#col.title = [line[1]]
	title = line[1]
	title.gsub!("&amp;","&")
	col.title = [title]
	col.former_id = [line[0].strip]
	col = populate_collection(line[0].strip, col, foxpath)
	col.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	col.depositor = user
	col.save!
	col_id = col.id.to_s
	puts "subject col id was" + col_id
	topcol.members << col
	topcol.save!
	mappings_string = line[0] + "," +  + line[1] + "," + col_id 
	mappings_level2.push(mappings_string)
	# add to hash, old pid as key, new id as value
	key = line[0]	
	idmap[key] = col.id
end

# write to file as  permanent mapping that we can use when mapping theses against collections
open(mapping_file, "a+")do |mapfile| 
# open("/vagrant/files_to_test/col_mapping.txt", "a+")do |mapfile|
	mapfile.puts(mappings_level2)
end

# but we still have our mappings array, so  now use this to make third level collections

sleep 5 # wait 5 seconds before moving on to allow 2nd level collections some time to index before the level3s start trying to find them

# read in third level file
mappings_level3 = []
# csv_text3 = File.read("/vagrant/files_to_test/thesescollectionsLevel3SMALL.txt")
level3collsfile = mapping_path + "UGpaperCollsLevel3.txt"
csv_text3 = File.read(level3collsfile)
# csv_text3 = File.read("/vagrant/files_to_test/thesescollectionsLevel3.txt")
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
	year_col_title.gsub!("&amp;", "&")
	puts "got level 3 title which was " + year_col_title
	year_col.title = [year_col_title] #just in case
	year_col.former_id = [line[0].strip]
	year_col = populate_collection(line[0].strip, year_col, foxpath)
	year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	year_col.depositor = user
	puts "saved permissions and depositor for year collection"
	year_col.save!
	puts "saved collection"
	year_col_id = year_col.id.to_s
	puts "year col id was " + year_col_id
	# need to find the right parent collection here	
	parent_pid = line[2]# old parent pid, key to find new parent id
	puts " subject col pid was " + parent_pid
	mapped_parent_id = idmap[parent_pid]	
	puts "mapped parent id was " + mapped_parent_id
	parent = Object::Collection.find(mapped_parent_id)
	parent.members << year_col
	puts "parent id was" + parent.id.to_s
	puts "year collection id was" + year_col.id.to_s
	parent.save!
	puts "parent.members were" + parent.members.to_s
	mappings_string = line[0] + "," +  + line[1] + "," + year_col_id 
	mappings_level3.push(mappings_string)
end

# and write to permanent mapping file - these can be all the same whether level 2 or 3 or  1
open(mapping_file, "a+")do |mapfile|
	mapfile.puts(mappings_level3)
end

puts "done"
=begin
information we need for each collection is the old pid as a key, plus its parent pid, plus the collection name and the new id once it is created
top level will be the top level theses ie current Masters Dissertations (york:18179). 
second level  is discipline eg Archaeology, Education etc
OPTIONAL third level is year eg 1973. Not all disciplines have this level
=end
end  # of method


def populate_collection(former_id, collection, foxpath)
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
description.gsub!("&amp;","&")
collection.description = [description]
#subjects (for now)
keywords = []
doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
    s = s.to_s
    s.gsub!("&amp;","&")
	keywords.push(s.to_s)
end
defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
coll_rights = defaultLicence
coll_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
common = CommonMigrationMethods.new
newrights =  common.get_standard_rights(coll_rights)#  all theses currently York restricted 	
if newrights.length > 0
	coll_rights = newrights	
end	
collection.rights=[coll_rights]
return collection
end  #end of populate_collection method



# devserver rake migration_tasks:bulk_migrate_undergrad_papers[/home/dlib/testfiles/foxml/UGpapers/bulktest,/home/dlib/testfiles/foxdone,https://dlib.york.ac.uk,/home/dlib/mapping_files/ug_col_mapping.txt]
def migrate_lots_of_ug_papers(path_to_fox, path_to_foxdone, content_server_url, collection_mapping_doc_path, user)
puts "doing a bulk migration from " + path_to_fox

fname = "tally.txt"
tallyfile = File.open(fname, "a")
Dir.foreach(path_to_fox)do |item|	
	# we dont want to try and act on the current and parent directories
	next if item == '.' or item == '..'
	# trackingfile.puts("now working on " + item)
	puts "found" + item.to_s
	itempath = path_to_fox + "/" + item
	result = 9  # so this wont do the actions required if it isnt reset
	begin
		result = migrate_undergraduate_paper(itempath, content_server_url, collection_mapping_doc_path, user)
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
	elsif result == 2   # apparently some records may not have an actual resource paper of any id!
		tallyfile.puts("ingested metadata but NO MAIN RESOURCE DOCUMENT IN "+ itempath)
		#sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
	elsif result == 3   # couldnt identify parent collection in mappings
		tallyfile.puts("FAILED TO INGEST " + itempath + " because couldnt identiy parent collection mapping")
		sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
	elsif result == 4   # this may well not work, as it may stop part way through before it ever gets here. 
		tallyfile.puts("FAILED TO INGEST RESOURCE DOCUMENT IN"+ itempath)
		sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
	else
        tallyfile.puts(" didnt return expected value of 0 or 1 ")	
	end
end
tallyfile.close
puts "all done"
end # end migrate_lots_of_theses_with_content_url



#
# my inprogress method with most of the content gone
# signature: # rake migration_tasks:migrate_undergrad_paper[/home/dlib/testfiles/foxml/UGpapers/york_933437.xml,https://dlib.york.ac.uk,/home/dlib/mapping_files/ug_col_mapping.txt,ps552@york.ac.uk]
def migrate_undergraduate_paper(path, content_server_url, collection_mapping_doc_path, user) 
result = 1 # default is fail
mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . (app one is not namespaced)
common = CommonMigrationMethods.new
puts "migrating a ug_paper with content url"	
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
	former_parent_pid = untrimmed_former_parent_pid.sub 'info:fedora/york', 'york'
	parentcol = collection_mappings[former_parent_pid]
	# find max dc version
	nums = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/@ID",ns)	
	all = nums.to_s
	current = all.rpartition('.').last 
	currentVersion = 'DC.' + current
	
	# find the max THESIS_MAIN or EXAM_PAPER version
	mainDocFound=""
	#check for one or the other with an active state A
	mainDocFound = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN'][@STATE='A']/@VERSIONABLE",ns).to_s
	if mainDocFound.length > 0
	 main_resource_id = "THESIS_MAIN"
	else
		mainDocFound = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER'][@STATE='A']/@VERSIONABLE",ns).to_s
		if mainDocFound.length > 0 
			main_resource_id = "EXAM_PAPER"
		end
	end	
	if mainDocFound.length > 0 && main_resource_id == "THESIS_MAIN"
		paper_nums = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion/@ID",ns)	
	elsif mainDocFound.length > 0 && main_resource_id == "EXAM_PAPER"
		paper_nums = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/foxml:datastreamVersion/@ID",ns)
	else
	#do nothing. apparently there are some in the live system without any main file
		#result = 2 # this will trigger putting a specific message into the tracking file
		#return 
	end	
	if mainDocFound.length > 0
		paper_all = paper_nums.to_s
		paper_current = paper_all.rpartition('.').last
		currentPaperVersion = main_resource_id + '.' + paper_current
		# GET CONTENT - get the location of the pdf as a string
		#pdf_loc = 	doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion[@ID='#{currentPaperVersion}']/foxml:contentLocation/@REF",ns).to_s	
		pdf_loc = doc.xpath("//foxml:datastream[@ID='" + main_resource_id + "']/foxml:datastreamVersion[@ID='#{currentPaperVersion}']/foxml:contentLocation/@REF",ns).to_s
		# CONTENT FILES	
		externalpdfurl = pdf_loc.sub 'http://local.fedora.server', content_server_url 
		externalpdflabel = main_resource_id  #default
		# actual label for gui display may be different
		label = doc.xpath("//foxml:datastream[@ID='" + main_resource_id + "']/foxml:datastreamVersion[@ID='#{currentPaperVersion}']/@LABEL",ns).to_s 
		if label.length > 0
			externalpdflabel = label 
		end
	end
# hash for any THESIS_ADDITIONAL URLs. needs to be done here rather than later to ensure we obtain overridden version og FileSet class rather than CC as local version not namespaced
#not needed for any yet. uncomment if live ingest contains any with additional resources and edit accordingly
=begin
    additional_filesets = {}	
	elems = doc.xpath("//foxml:datastream[@ID]",ns)
	elems.each { |id| 
		idname = id.attr('ID')		
		if idname.start_with?('THESIS_ADDITIONAL')
		idstate = id.attr('STATE')
		if idstate == "A"
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
			fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			fileset.depositor = "ps552@york.ac.uk"
			additional_filesets[idname] = fileset
			end
		end
	}
=end  #coz there dont seem to be any in this collection
		
	# create a new thesis implementing the dlibhydra models
	ug_paper = Object::Thesis.new  #we have decided to use this model
	# once depositor and permissions defined, object can be saved at any time
	ug_paper.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	ug_paper.depositor = user
	
	# start reading and populating  data
	title =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	title = title.to_s
	title.gsub!("&amp;","&")
	
	ug_paper.title = [title]	# 1 only
	former_id = doc.xpath("//foxml:digitalObject/@PID",ns).to_s
	if former_id.length > 0
		ug_paper.former_id = [former_id]
	end
	
	# file to list what its starting work on as a cleanup tool. doesnt matter if it doesnt get this far as there wont be anything to clean up
	tname = "ug_tracking.txt"
	trackingfile = File.open(tname, "a")
	trackingfile.puts( "am now working on " + former_id + " title:" + title )
	trackingfile.close	
	creators = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns).each  do |c|
		creator = c.to_s
		creators.push(creator)
	end
	#may not always be present 
	creators.each do |creator|
		creator.gsub!("&amp;","&") #unlikely but no harm done - could be group projects
		ug_paper.creator_string += [creator] # now multivalued
	end
	# essays and projects have a description rather than an abstract  optional field so test presence
	paper_descriptions = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:description/text()",ns).each do |d|
	    d = d.to_s
		d.gsub!("&amp;","&")
		paper_descriptions.push(d)		
	end
	paper_descriptions.each do |d|
		d.gsub!("&amp;","&") 
		ug_paper.description += [d] # now multivalued
	end
	
	
	# use date_of_award for UG papers - metadata team have confirmed
	paper_date = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:date/text()",ns).to_s	
	if paper_date.length > 0
		#ug_paper.date = [paper_date] 
		ug_paper.date_of_award = paper_date
	end
	# advisor 0... 1 so check if present
	paper_advisor = []
	   doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:contributor/text()",ns).each do |i|
		paper_advisor.push(i.to_s)
	end
	paper_advisor.each do |c|
		ug_paper.advisor_string.push(c)
	end	
	
	 # departments and institutions 
	#in this collection the loc may also be defined in the creator!
   locations = []
	 doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:publisher/text()",ns).each  do |i|
		locations.push(i.to_s)
	 end
	 
	 #if publisher element is not present (which may be the case for essays and projects) see if creator is present, and if so, if it contains the right sort of content - ie a university department rather than a personal name
	 if locations.size == 0
		if creators.size > 0
			creators.each {|c|
			puts "c was" + c.to_s
				if c.downcase.include? "department" or c.downcase.include? "dept" or c.downcase.include? "university" or c.downcase.include? "school" or c.downcase.include? "centre"
					locations.push(c.to_s)
				end
			}		
		end
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
			id = common.get_resource_id('institution', preflabel)
			ug_paper.awarding_institution_resource_ids+=[id]
		end
				
		# department
		dept_preflabels = common.get_department_preflabel(loc)		 
		if dept_preflabels.empty?
			puts "no department found"
		end
		dept_preflabels.each do | preflabel|
			id = common.get_resource_id('department', preflabel)
			ug_paper.department_resource_ids +=[id]
		end
	end
	
	# qualification level, name, resource type
	typesToParse = []  #
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns).each do |t|	
	typesToParse.push(t)
	end
	# qualification names (object)
	#will we need this?
	qualification_name_preflabels = common.get_qualification_name_preflabel(typesToParse)
	if qualification_name_preflabels.length == 0 
		puts "no qualification name preflabel found"
	end
	qualification_name_preflabels.each do |q|	
		qname_id = common.get_resource_id('qualification_name',q)
		if qname_id.to_s != "unfound"		
			ug_paper.qualification_name_resource_ids+=[qname_id]
		else
			puts "no qualification nameid found"
		end
	end	
	# qualification levels (yml file). this wont really work as mapped for the other files, but can modify here by searching for anything in types including the term indicating a batchelors
	#degree then forcing it. may also need to try for other things
	typesToParse.each do |t|	
		type_to_test = t.to_s
		qual_levels = []
		levels = common.get_qualification_level_term(type_to_test)
		levels.each do |level|
			if !qual_levels.include? level
				qual_levels.push(level)
			end	
		end
		qual_levels.each do |dl|
			ug_paper.qualification_level += [dl]
		end
		
		# now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
		# resource Types map to dc:subject. at present the only official value is Dissertations, Academic
		#should this still be here for UG essays and projects?
		#im assuming that in the case of undergraduate dc:type labelled project rather than thesis, this should still be given the theis subject type 
		theses = [ 'theses','Theses','Dissertations','dissertations','project','Project' ]   #KALE should this still be here for UG essays and projects?
		if theses.include? type_to_test	
		# not using methods below yet - or are we? subjects[] no longer in model
			subject_id = common.get_resource_id('subject',"Dissertations, Academic")
			ug_paper.subject_resource_ids +=[subject_id]		 
		end
	end
	
	paper_language = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:language/text()",ns).each do |lan|
	paper_language.push(lan.to_s)
	end	
	paper_language.each do |lan|   #0 ..n
	standard_language = "unfound"
	    standard_language = common.get_standard_language(lan.titleize)#capitalise first letter
		if standard_language!= "unfound"
			ug_paper.language+=[standard_language]
		end
	end	
	
	# dc.keyword (formerly subject, as existing ones from migration are free text not lookup
	paper_subject = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
	paper_subject.push(s.to_s)
	end
	paper_subject.each do |s|
		s.gsub!("&amp;","&")
		ug_paper.keyword+=[s]   #TODO:: ADDED TO FEDORA AS DC.RELATION NOT DC(OR DC11).SUBJECT!!!
	end	
	
	# rights.	
	# rights holder 0...1
	# checked data on dlib. all have the same rights statement and url cited, so this should work fine, as everything else is rights holders   
   paper_rightsholder = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[not(contains(.,'http')) and not (contains(.,'licenses')) ]",ns).to_s
   if paper_rightsholder.length > 0
	ug_paper.rights_holder=[paper_rightsholder] 
   end
   
   # license  set a default which will be overwritten if one is found. its the url, not the statement. use licenses.yml not rights_statement.yml
	# For full york list see https://dlib.york.ac.uk/yodl/app/home/licences. edit in rights.yml
	defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
	paper_rights = defaultLicence
	paper_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
	
	newrights =  common.get_standard_rights(paper_rights)#  all theses currently York restricted 	
	if newrights.length > 0
		paper_rights = newrights
		ug_paper.rights=[paper_rights]			
	end	
	
	#check the collection exists before saving and putting in collection
	# save	
	if Object::Collection.exists?(parentcol.to_s)
		ug_paper.save!
		id = ug_paper.id
		puts "paper id was " +id 
		puts "parent col was " + parentcol.to_s
		col = Object::Collection.find(parentcol.to_s)
		puts "id of col was:" +col.id
		puts " collection title was " + col.title[0].to_s
		col.members << ug_paper  
		col.save!
	else
		puts "couldnt find collection " + parentcol.to_s
		return
	end
	
	if mainDocFound.length > 0
		users = Object::User.all #otherwise it will use one of the included modules
		user_object = users[0]
		puts "got the user"
		begin
			# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
			#mfset.filetype = 'externalurl'
			mfset.filetype = 'managed'
			# make this the same as the label
			mfset.title = [externalpdflabel]	#needs to be same label as content file label in foxml 
			mfset.label = externalpdflabel
			# add the external content URL
			mfset.external_file_url = externalpdfurl
			puts "added external file url" + externalpdfurl
			actor = CurationConcerns::Actors::FileSetActor.new(mfset, user_object)
			actor.create_metadata(ug_paper)
			#Declare file as external resource
			Hydra::Works::AddExternalFileToFileSet.call(mfset, externalpdfurl, 'external_url')
			mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			mfset.depositor = user
			mfset.save!
			puts "fileset " + mfset.id + " saved"
    
			#this is here because the system tended to lock up during multiple uploads - suspect competition for resources or threading issue somewhere
			sleep 20 		
			ug_paper.mainfile << mfset
			sleep 20  
			ug_paper.save!
		rescue
			puts "QUACK QUACK OOPS! addition of external file unsuccesful"
			result = 4
			return result		
		end   
		puts "all done for external content mainfile " + id 
		result = 0 		
	 else
		result = 2
	 end

#uncomment and edit this if any additional resource files found in records
=begin
	for key in additional_filesets.keys() do		
		additional_thesis_file_fs = additional_filesets[key]
        actor = CurationConcerns::Actors::FileSetActor.new(additional_thesis_file_fs, user_object)
        actor.create_metadata(ug_paper)
		url = additional_thesis_file_fs.external_file_url
        Hydra::Works::AddExternalFileToFileSet.call(additional_thesis_file_fs, url, 'external_url')
        additional_thesis_file_fs.save!
		ug_paper.members << additional_thesis_file_fs
        ug_paper.save!
		puts "all done for  additional file " + key
	end
=end
	 
	#when done, explicity reset big things to empty to ensure resources not hung on to
	#additional_filesets = {}  uncomment if additional content files
    doc = nil
	mapping_text = nil
	collection_mappings = {}	
	
	return result   # give it  a return value
end # end of single paper migration

end # end of class
