# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# methods to create the  collection structure and do migrations
class FoxmlReader
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra

#check its at least valid ruby
def test
puts "yup, foxml_reader still working"
end



=begin
*the list of possible collections under theses is quite extensive - get it from an risearch query
*thesescollections.txt contains all the returned data from risearch for all levels
*thesescollectionsLevel2|3.txt is a complete cleaned up list of level 2|3 collections ready for use. 
*format is: old pid of collection,title of collection,old parent_pid
*col_mapping.txt is output by the script and is the permanent mapping file. format:
originalpid, title, newid 
so call is like rake migration_tasks:make_collection_structure[/home/dlib/mapping_files/,/home/dlib/testfiles/foxml/]
=end

def make_collection_structure(mapping_path, foxpath)
puts "running make_collection_structure"
mapping_file = mapping_path +"col_mapping.txt"
# make the top Theses level first, with a CurationConcerns (not dlibhydra) model.
#array of lines including title
topmapping = []
# we also need a pid:id hash so we can extract id via a pid key
idmap ={}
toppid = "york:18179"    #top level collection
topcol = Object::Collection.new
topcol.title = ["Masters dissertations"]
topcol.former_id = [toppid]
topcol = populate_collection(toppid, topcol, foxpath)  
#the top collection is visible to the general public but not the underlying records or collections
topcol.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
topcol.depositor = "ps552@york.ac.uk"
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
level2file = mapping_path + "thesescollectionsLevel2.txt"
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
	col.depositor = "ps552@york.ac.uk"
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
level3collsfile = mapping_path + "thesescollectionsLevel3.txt"
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
	year_col_title = line[1].to_st 
	puts "got level 3 title which was " + year_col_title
	year_col.title = [year_col_title.gsub!("&amp;", "&")] #just in case
	year_col.former_id = [line[0].strip]
	year_col = populate_collection(line[0].strip, year_col, foxpath)
	year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	year_col.depositor = "ps552@york.ac.uk"
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

#could do with populating collection objects further, although no model mapping avail in google  docs
#in exams i can see creator, description, title,rights,subject, and I think we also need former id
#available attributes:  collections_category: [], former_id: [], publisher: [], rights_holder: [], rights: [], license: [], language: [], language_string: [], keyword: [], description: [], date: [], creator_string: [], title: [], rdfs_label: nil, preflabel: nil, altlabel: [], depositor: nil, date_uploaded: nil, date_modified: nil, head: [], tail: [], publisher_resource_ids: [], subject_resource_ids: [], creator_resource_ids: [], access_control_id: nil, representative_id: nil, thumbnail_id: nil>
#will need to export the full list of foxml objects first, doh
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

=begin
keep this for present as it is the only way of making a new child collection within the existing structure (the one on the interface does not allow 
you to specify the correct parent to add to - only shows some, and no way to distinguish between groups of year collections
call is like rake migration_tasks:make_collection_structure[/home/ubuntu/dlib/mapping_files/]
so where the child being added has pid york:1234, is called 1999, and is a child of york:4567
so to create the old english/
new english id is m039k4882
  old year collection title was 2015 
  old year collection id was york:932220
 call is like rake migration_tasks:recreate_child_collection[york:932220,2015,m039k4882,/home/ubuntu/mapping_files/]
 rake migration_tasks:recreate_child_collection[york:932221,2016,m039k4882,/home/ubuntu/mapping_files/]
=end
def recreate_child_collection(old_pid, title, parent_id, mapping_path)
#coll = Object::Collection.new
mapping_file = mapping_path +"col_mapping.txt"
puts "mapping file was " + mapping_file
puts "old year pid was " + old_pid
puts "old year title was " + title
puts "parent id was " + parent_id
mapping = []
coll = Object::Collection.new
#coll.preflabel = "stuff I made"
coll.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
coll.depositor = "ps552@york.ac.uk"
coll.title = [title]

coll.save!
child_id = coll.id
puts "collection id was " +child_id
parent_col = Object::Collection.find(parent_id)	
	puts " collection title was " + parent_col.title[0].to_s
parent_col.members << coll	
parent_col.save!   #saving this IS neccesary
mapping_string = old_pid + "," +  + coll.title[0].to_s + "," + child_id #former pid of child +title of child plus new id of child
mapping.push(mapping_string)
#add to mapping file
open(mapping_file, "a+")do |mapfile|
	mapfile.puts(mapping)
end

end #end recreate_child_collection




# bundle exec rake migration_tasks:migrate_lots_of_theses[/vagrant/files_to_test/app3fox,/vagrant/files_to_test/col_mapping.txt
# MEGASTACK rake migration_tasks:migrate_lots_of_theses[/home/ubuntu/testfiles/foxml,/home/ubuntu/testfiles/foxdone,/home/ubuntu/mapping_files/col_mapping.txt]
# devserver rake migration_tasks:migrate_lots_of_theses[/home/dlib/testfiles/foxml,/home/dlib/testfiles/foxdone,/home/dlib/testfiles/content/,/home/dlib/mapping_files/col_mapping.txt]
def migrate_lots_of_theses(path_to_fox, path_to_foxdone, contentpath, collection_mapping_doc_path)
puts "doing a bulk migration"
fname = "tally.txt"
# tname = "tracking.txt"  PUT THIS IN MIGRATE_THESIS TO GET TITLE 
# could really do with a file to list what its starting work on as a debug tool
# trackingfile = File.open(tname, "a")
tallyfile = File.open(fname, "a")
Dir.foreach(path_to_fox)do |item|	
	# we dont want to try and act on the current and parent directories
	next if item == '.' or item == '..'
	# trackingfile.puts("now working on " + item)
	itempath = path_to_fox + "/" + item
	# migrate_thesis(itempath,collection_mapping_doc_path)
	result = 2  # so this wont do the actions required if it isnt reset
	begin
		result = migrate_thesis(itempath,contentpath,collection_mapping_doc_path)
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
# trackingfile.close
end  # end migrate_lots_of_theses


# MEGASTACK rake migration_tasks:migrate_lots_of_theses_with_content_url[/home/ubuntu/testfiles/foxml,/home/ubuntu/testfiles/foxdone,/home/ubuntu/mapping_files/col_mapping.txt]
# devserver rake migration_tasks:migrate_lots_of_theses_with_content_url[/home/dlib/testfiles/foxml,/home/dlib/testfiles/foxdone,https://dlib.york.ac.uk,/home/dlib/mapping_files/col_mapping.txt]
def migrate_lots_of_theses_with_content_url(path_to_fox, path_to_foxdone, content_server_url, collection_mapping_doc_path)
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


# bundle exec rake migrate_thesis[/vagrant/files_to_test/york_847953.xml,9s1616164]
# bundle exec rake migrate_thesis[/vagrant/files_to_test/york_21031.xml,9s1616164]
# def migrate_thesis(path,collection)
# bundle exec rake migrate_thesis[/vagrant/files_to_test/york_21031.xml,/vagrant/files_to_test/col_mapping.txt]
# emotional world etc
# bundle exec rake migrate_thesis[/vagrant/files_to_test/york_807119.xml,/vagrant/files_to_test/col_mapping.txt]   
# bundle exec rake migration_tasks:migrate_thesis[/vagrant/files_to_test/york_847953.xml,/vagrant/files_to_test/col_mapping.txt]
# bundle exec rake migration_tasks:migrate_thesis[/vagrant/files_to_test/york_847943.xml,/vagrant/files_to_test/col_mapping.txt]
# on megastack: # rake migration_tasks:migrate_thesis[/home/ubuntu/testfiles/foxml/york_xxxxx.xml,/home/ubuntu/testfiles/content/,/home/ubuntu/mapping_files/col_mapping.txt]
# new signature: # rake migration_tasks:migrate_thesis[/home/dlib/testfiles/foxml/york_xxxxx.xml,/home/dlib/testfiles/content/,/home/dlib/mapping_files/col_mapping.txt]
def migrate_thesis(path, contentpath, collection_mapping_doc_path)
# mfset = Dlibhydra::FileSet.new   # FILESET. # defin this at top because otherwise expects to find it in CurationConcerns module 
result = 1 # default is fail
mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . 
common = CommonMigrationMethods.new

puts "migrating a thesis using path " + path +" and  contentPath " + contentpath + " collection_maPPING_DOC_PATH " + collection_mapping_doc_path		
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
	
	
	# now see if the collection mapping is in here
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
	
	# find the max THESIS_MAIN version
	thesis_nums = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion/@ID",ns)	
	thesis_all = thesis_nums.to_s
	thesis_current = thesis_all.rpartition('.').last 
	currentThesisVersion = 'THESIS_MAIN.' + thesis_current
	# GET CONTENT - get the location of the pdf as a string
	pdf_loc = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion[@ID='#{currentThesisVersion}']/foxml:contentLocation/@REF",ns).to_s	
	
	# CONTENT FILES
	# this has local.fedora.host, which will be wrong. need to replace this 
	# reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	# needs to read (for development purposes on real machine) https://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	# newpdfloc = pdf_loc.sub 'local.fedora.server', 'yodlapp3.york.ac.uk'  # CHOSS we dont need this any more as we cant download remotely
	localpdfloc = pdf_loc.sub 'http://local.fedora.server', contentpath #this will be added to below. once we have external urls can add in relevant url
    # ADDED 14th June for base name**********************************************************	
	basename = File.basename(localpdfloc)
	# comment out line below if redirecting to external url rather than ingesting local
	localpdfloc = contentpath + basename  #not a repeat but an addition
	# end of addition*****************************	
	
	# dont continue to migrate file if content file not found
	if !File.exist?(localpdfloc)
		puts 'content file ' + localpdfloc.to_s + ' not found'	
		return	
	end 
	# for initial development purposes on my machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
		
	
	# create a new thesis implementing the dlibhydra models
	thesis = Object::Thesis.new

	# once depositor and permissions defined, object can be saved at any time
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	thesis.depositor = "ps552@york.ac.uk"
	
	# start reading and populating  data
	titleArray =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	t = titleArray.to_s 
	t.gsub!("&amp;","&")
		
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
		thesis_abstract.gsub!("&amp;","&")
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
			id = common.get_resource_id('institution', preflabel)
			thesis.awarding_institution_resource_ids+=[id]
		end
				
		# department
		dept_preflabels = get_department_preflabel(loc)		 
		if dept_preflabels.empty?
			puts "no department found"
		end
		dept_preflabels.each do | preflabel|
			id = common.get_resource_id('department', preflabel)
			thesis.department_resource_ids +=[id]
		end
	end
	
	
	# qualification level, name, resource type
	typesToParse = []  #
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns).each do |t|	
	typesToParse.push(t)
	end
	# qualification names (object)
	qualification_name_preflabels = common.get_qualification_name_preflabel(typesToParse)
	if qualification_name_preflabels.length == 0 
		puts "no qualification name preflabel found"
	end
	qualification_name_preflabels.each do |q|	
		qname_id = common.get_resource_id('qualification_name',q)
		if qname_id.to_s != "unfound"		
			thesis.qualification_name_resource_ids+=[qname_id]
		else
			puts "no qualification nameid found"
		end
	end	
	
	# qualification levels (yml file). there can only be one
	typesToParse.each do |t|	
	type_to_test = t.to_s
	degree_levels = common.get_qualification_level_term(type_to_test)
	degree_levels.each do |dl|
		thesis.qualification_level += [dl]
	end

	# now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
	# resource Types map to dc:subject. at present the only official value is Dissertations, Academic
	theses = [ 'theses','Theses','Dissertations','dissertations' ] 
	if theses.include? type_to_test	
	# not using methods below yet - or are we? subjects[] no longer in model
		subject_id = common.get_resource_id('subject',"Dissertations, Academic")
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
	    standard_language = common.get_standard_language(lan.titleize)#capitalise first letter
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
		s.gsub!("&amp;","&")
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
	
	newrights =  common.get_standard_rights(thesis_rights)#  all theses currently York restricted 	
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
	begin
		# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
		users = Object::User.all #otherwise it will use one of the included modules
		user = users[0]	
		mfset.filetype = 'embeddedfile'
		mfset.title = ["THESIS_MAIN"]	#needs to be same label as content file in foxml 
		mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
		mfset.depositor = "ps552@york.ac.uk"
		mfset.save!
	
		# THE NEXT FOUR LINES UPLOAD THE CONTENT INTO THE FILESET AND CREATE A THUMBNAIL
	
		# local_file = Hydra::Derivatives::IoDecorator.new(File.open(localpdfloc, "rb"))  #CHOSS IOdecorator gets called further down the stack anyway
		local_file = File.open(localpdfloc, "rb")		
		relation = "original_file"	
		fileactor = CurationConcerns::Actors::FileActor.new(mfset,relation,user)
		fileactor.ingest_file(local_file) #according to the documentation this method should produce derivatives as well
		mfset.save!	
	
		# THe NEXT TWO LINES ARE NEEDED TO ATTACH THE FILESET AND CONTENT TO THE WORK 
		actor = CurationConcerns::Actors::FileSetActor.new(mfset, user)
		puts "CHOSS about to create metadata for thesis content"
		actor.create_metadata(thesis)#name of object its to be added to #if you leave this out it wont create the metadata showing the related fileset
		puts "CHOSS created metadata for thesis content"
		# create_content does not seem to be required if we are using fileactor.ingest_file, and does not make any difference to download icon
		# actor.create_content(contentfile, relation = 'original_file' )
		# actor.create_content(contentfile) #15.03.2017 CHOSS
		# actor.create_content(local_file)
		# TELL THESIS THIS IS THE MAIN_FILE. assume this also sets mainfile_ids[]
    rescue
	  # CHOSS this may creat a problem during multiple uploads
		sleep 20 		
		 thesis.mainfile << mfset	
		sleep 20  
		 thesis.save!
		result = 1
		return result
   end
   # try explicitly cloing local_file and setting agents to nil so garbage will be collected
   # puts "now about to close file "
   # local_file.close   #doesnt seem to help
   # puts " closed local file "
   # fileactor = nil
   # puts "fileactor nilled"
   # actor = nil 
   # puts "actor nilled"
   # actor.nil
   # puts "files closed, actors nilled"
   puts "all done for file " + id   
   result = 0
   return result   # give it  a return value
end # end of migrate thesis

#version of migration that adds the content file url but does not ingest the content pdf into the thesis
# on megastack: # rake migration_tasks:migrate_thesis_with_content_url[/home/ubuntu/testfiles/foxml/york_xxxxx.xml,/home/ubuntu/mapping_files/col_mapping.txt]
# new signature: # rake migration_tasks:migrate_thesis_with_content_url[/home/dlib/testfiles/foxml/mytest.xml,https://dlib.york.ac.uk,/home/dlib/mapping_files/col_mapping.txt]
def migrate_thesis_with_content_url(path, content_server_url, collection_mapping_doc_path) 
result = 1 # default is fail
mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . (app one is not namespaced)
common = CommonMigrationMethods.new
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
	former_parent_pid = untrimmed_former_parent_pid.sub 'info:fedora/york', 'york'
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
			fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
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
			fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			fileset.depositor = "ps552@york.ac.uk"
			additional_filesets[idname] = fileset
		end
	}
		
	# create a new thesis implementing the dlibhydra models
	thesis = Object::Thesis.new

	# once depositor and permissions defined, object can be saved at any time
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	thesis.depositor = "ps552@york.ac.uk"
	
	# start reading and populating  data
	titleArray =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	t = titleArray.to_s
	t.gsub!("&amp;","&")
		
	thesis.title = [t]	# 1 only	
	# thesis.preflabel =  thesis.title[0] # skos preferred lexical label (which in this case is same as the title. 1 0nly but can be at same time as title 
	#EEK! not all the records have dc:identifier populated
	#former_id = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:identifier/text()",ns).to_s
	former_id = doc.xpath("//foxml:digitalObject/@PID",ns).to_s
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
	thesis_abstract.gsub!("&amp;","&")
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
			id = common.get_resource_id('institution', preflabel)
			thesis.awarding_institution_resource_ids+=[id]
		end
				
		# department
		dept_preflabels = common.get_department_preflabel(loc)		 
		if dept_preflabels.empty?
			puts "no department found"
		end
		dept_preflabels.each do | preflabel|
			id = common.get_resource_id('department', preflabel)
			thesis.department_resource_ids +=[id]
		end
	end
	
	
	# qualification level, name, resource type
	typesToParse = []  #
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns).each do |t|	
	typesToParse.push(t)
	end
	# qualification names (object)
	
	qualification_name_preflabels = common.get_qualification_name_preflabel(typesToParse)
	if qualification_name_preflabels.length == 0 
		puts "no qualification name preflabel found"
	end
	qualification_name_preflabels.each do |q|	
		qname_id = common.get_resource_id('qualification_name',q)
		if qname_id.to_s != "unfound"		
			thesis.qualification_name_resource_ids+=[qname_id]
		else
			puts "no qualification nameid found"
		end
	end	
	
	
	# qualification levels (yml file). 
	typesToParse.each do |t|	
	type_to_test = t.to_s
	degree_levels = common.get_qualification_level_term(type_to_test)
	degree_levels.each do |degree_level|
		thesis.qualification_level += [degree_level]
	end

	# now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
	# resource Types map to dc:subject. at present the only official value is Dissertations, Academic
	theses = [ 'theses','Theses','Dissertations','dissertations' ] 
	if theses.include? type_to_test	
	# not using methods below yet - or are we? subjects[] no longer in model
		subject_id = common.get_resource_id('subject',"Dissertations, Academic")
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
	    standard_language = common.get_standard_language(lan.titleize)#capitalise first letter
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
		s.gsub!("&amp;","&")
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
	
	newrights =  common.get_standard_rights(thesis_rights)#  all theses currently York restricted 	
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
		mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
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
