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

def say_hello
	puts "HODOR!"
end

#mapping_path is path to the mapping file, foxpath is the path to the existing foxml collection files 
#note there are two collectiuon hierarchies, one of which is admin restricted and in the admin only collection on dlib, the papers within here are also required
def make_exam_collection_structure(mapping_path, foxpath, user)
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
#the top collection is visible to the general public but not the underlying records or collections
topcol.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
topcol.depositor = user
topcol.save!
topcol_id = topcol.id.to_s
puts "topcol.id was " +topcol.id
mappings_string = toppid + "," + topcol.title[0].to_s + "," + topcol_id 
topmapping.push(mappings_string) 
# add to hash, old pid as key, new id as value
key = toppid	
idmap[key] = topcol.id
# write to file as  permanent mapping that we can use when mapping theses against collections 
open(mapping_file, "a+") do |mapfile|
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
	year_col_title.gsub!("&amp;","&")
	year_col.title =  [year_col_title]
	year_col.former_id = [line[0].strip]
	year_col = populate_collection(line[0].strip, year_col, foxpath)
	year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	year_col.depositor = user
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
    puts "starting number " + yearpidcount.to_s + " in list"
    puts line[0]
	physics_year_col = Object::Collection.new
	puts "started new physics year collection"
	# col = Dlibhydra::Collection.new extend cc collection instead
	year_col_title = line[1].to_s
	year_col_title.gsub!("&amp;","&")
	puts "got level 4 title which was " +year_col_title
	physics_year_col.title =  [year_col_title]
	physics_year_col.former_id = [line[0].strip]
	physics_year_col = populate_collection(line[0].strip, physics_year_col, foxpath)  
	physics_year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	physics_year_col.depositor = user
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

#mapping_path is path to the mapping file, foxpath is the path to the existing foxml collection files 
#note there are two collectiuon hierarchies, one of which is admin restricted and in the admin only collection on dlib, the papers within here are also required
#rake migration_tasks:make_restricted_exam_collection_structure[/home/dlib/mapping_files/tests/,/home/dlib/testfiles/foxml/]
def make_restricted_exam_collection_structure(mapping_path, foxpath, user)
puts "running make_exam_collection_structure"
mapping_file = mapping_path +"exam_col_mapping.txt"
# make the top Exams level first, with a CurationConcerns (not dlibhydra) model.
#array of lines including title
topmapping = []
# we also need a pid:id hash so we can extract id via a pid key
idmap ={}
toppid = "york:796226"    #top level collection
topcol = Object::Collection.new
topcol.title = ["Restricted exam papers"]
topcol.former_id = [toppid]
topcol = populate_collection(toppid, topcol, foxpath)
#the top collection is NOT visible to the general public 
topcol.permissions = [Hydra::AccessControls::Permission.new({:name=> "admin", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
topcol.depositor = user
topcol.save!
topcol_id = topcol.id.to_s
mappings_string = toppid + "," + topcol.title[0].to_s + "," + topcol_id 
topmapping.push(mappings_string) 
# add to hash, old pid as key, new id as value
key = toppid	
idmap[key] = topcol.id
# write to file as  permanent mapping that we can use when mapping theses against collections 
open(mapping_file, "a+") do |mapfile|
mapfile.puts(topmapping)
end

=begin
now we need to read from the list which I will create, splitting into appropriate parts and for each create an id and add it to the top level collection
=end
# hardcode second level file, but could pass in as param
level2file = mapping_path + "restrictedExamCollsLevel2.txt"
csv_text = File.read(level2file)
csv = CSV.parse(csv_text)
# we also need a file we can write to, as a permanent mapping
mappings_level2 = []

puts "starting second level(subjects)"
csv.each do |line|
    puts line[0]
	col = Object::Collection.new
	# col = Dlibhydra::Collection.new
	title = line[1]
	title.gsub!("&amp;","&")
	col.title = [title]
	former_id = line[0].strip
	col.former_id = [former_id]
	col = populate_collection(former_id, col, foxpath) 
	col.permissions = [Hydra::AccessControls::Permission.new({:name=> "admin", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	col.depositor = user
	col.save!
	col_id = col.id.to_s
	topcol.members << col
	topcol.save!
	mappings_string = former_id + "," + title + "," + col_id 
	mappings_level2.push(mappings_string)
	# add to hash, old pid as key, new id as value
	key = former_id	
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
level3collsfile = mapping_path + "restrictedExamCollsLevel3.txt"
csv_text3 = File.read(level3collsfile)
csv_level3 = CSV.parse(csv_text3)
yearpidcount = 0
puts "starting third level (years)"
csv_level3.each do |line|
yearpidcount = yearpidcount +1
    puts "starting number " +yearpidcount.to_s+ " in list"
    puts line[0]
	year_col = Object::Collection.new
	# col = Dlibhydra::Collection.new extend cc collection instead
	year_col_title = line[1].to_s
	year_col_title.gsub!("&amp;","&")
	year_col.title =  [year_col_title]
	former_id = line[0].strip
	year_col.former_id = [former_id]
	year_col = populate_collection(former_id, year_col, foxpath)
	year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "admin", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	year_col.depositor = user
	year_col.save!
	year_col_id = year_col.id.to_s
	# need to find the right parent collection here	
	parent_pid = line[2].strip# old parent pid, key to find new parent id
	mapped_parent_id = idmap[parent_pid]	
	parent = Object::Collection.find(mapped_parent_id)
	parent.members << year_col
	parent.save!
	mappings_string = former_id + "," + year_col_title + "," + year_col_id 
	mappings_level3.push(mappings_string)
	# add to hash, old pid as key, new id as value
	key = former_id	
	idmap[key] = year_col.id
end
# and write to permanent mapping file - these can be all the same file whatever level
open(mapping_file, "a+")do |mapfile|
	mapfile.puts(mappings_level3)
end

# level 4
sleep 5 # wait 5 seconds before moving on to allow 2nd level collections some time to index before the level3s start trying to find them
mappings_level4 = []
level4collsfile = mapping_path + "restrictedExamCollsLevel4.txt"
csv_text4 = File.read(level4collsfile)
csv_level4 = CSV.parse(csv_text4) 
yearpidcount = 0
puts "starting fourth level (physics years)"
csv_level4.each do |line|
	yearpidcount = yearpidcount +1
    puts "starting number " + yearpidcount.to_s + " in list"
    puts line[0]
	physics_year_col = Object::Collection.new
	# col = Dlibhydra::Collection.new extend cc collection instead
	year_col_title = line[1].to_s	
	year_col_title.gsub!("&amp;","&")
	year_col_pid = line[0].strip
	physics_year_col.title =  [year_col_title]
	physics_year_col.former_id = [year_col_pid]
	physics_year_col = populate_collection(year_col_pid, physics_year_col, foxpath)  
	physics_year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "admin", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	physics_year_col.depositor = user
	physics_year_col.save!
	physics_year_col_id = physics_year_col.id.to_s
	# need to find the right parent collection here	
	parent_pid = line[2].strip # old parent pid, key to find new parent id
	mapped_parent_id = idmap[parent_pid]	
	parent = Object::Collection.find(mapped_parent_id)
	parent.members << physics_year_col
	parent.save!
	mappings_string = year_col_pid + ","   + year_col_title + "," + physics_year_col_id 
	mappings_level4.push(mappings_string)
	# add to hash, old pid as key, new id as value
	key = year_col_pid	
	idmap[key] = physics_year_col_id
end
# write to permanent mapping file - these can be all the same file whatever level
open(mapping_file, "a+")do |mapfile|
	mapfile.puts(mappings_level4)	
end
#end of level 4


# level 5
sleep 5 # wait 5 seconds before moving on to allow 2nd level collections some time to index before the level3s start trying to find them
mappings_level5 = []
level5collsfile = mapping_path + "restrictedExamCollsLevel5.txt"
csv_text5 = File.read(level5collsfile)
csv_level5 = CSV.parse(csv_text5) 
yearpidcount = 0
puts "starting fifth level (physics solution years)"
csv_level5.each do |line|
	yearpidcount = yearpidcount +1
    puts "starting number " + yearpidcount.to_s + " in list"
	size = line.size
    formerpid = line[0].strip
	level5title = line[1].strip
	level5title.gsub!("&amp;","&")
	level5parent = line[2].strip
	level5_col = Object::Collection.new
	# col = Dlibhydra::Collection.new extend cc collection instead		
	level5_col.title =  [level5title]
	level5_col.former_id = [formerpid]
	level5_col = populate_collection(formerpid, level5_col, foxpath) 
	level5_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "admin", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	level5_col.depositor = user
	level5_col.save!
	new_id = level5_col.id.to_s
	# need to find the right parent collection here	
	mapped_parent_id = idmap[level5parent]	
	parentColl = Object::Collection.find(mapped_parent_id)
	parentColl.members << level5_col
	parentColl.save!
	mappings_string = formerpid + ","   + level5title + "," + new_id 
	mappings_level5.push(mappings_string)
end
# write to permanent mapping file - these can be all the same file whatever level
open(mapping_file, "a+")do |mapfile|
	mapfile.puts(mappings_level5)	
end
#end of level 5



puts "all collections done"

end # end make restricted_exam_collection_structure



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
puts "populating " + former_id
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
possible_coll_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
if possible_coll_rights.length > 0
  coll_rights = possible_coll_rights
end
puts "coll rights is " + coll_rights
common = CommonMigrationMethods.new
newrights = common.get_standard_rights(coll_rights)#  all exam papers currently York restricted 	
if newrights.length > 0
	coll_rights = newrights	
end	
collection.rights=[coll_rights]
puts "finished populating collection"
return collection
end  #end of populate_collection method


#start working thru this for exams :-)

# MEGASTACK rake migration_tasks:migrate_lots_of_exams[/home/dlib/testfiles/foxml/test,/home/dlib/testfiles/foxdone,https://dlib.york.ac.uk,/home/dlib/mapping_files/exam_col_mapping.txt]
# devserver rake migration_tasks:migrate_lots_of_exams[/home/dlib/testfiles/foxml,/home/dlib/testfiles/foxdone,https://dlib.york.ac.uk,/home/dlib/mapping_files/exam_col_mapping.txt]
def migrate_lots_of_exams(path_to_fox, path_to_foxdone, content_server_url, collection_mapping_doc_path, user)
puts "doing a bulk migration of exams"
fname = "exam_tally.txt"
tallyfile = File.open(fname, "a")
	
Dir.foreach(path_to_fox)do |item|	
	# we dont want to try and act on the current and parent directories
	next if item == '.' or item == '..'
	
	itempath = path_to_fox + "/" + item
	result = 2  # so this wont do the actions required if it isnt reset
	begin
		result = migrate_exam(itempath,content_server_url,collection_mapping_doc_path,user)
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
# new signature: # rake migration_tasks:migrate_exam_paper[/home/dlib/testfiles/foxml/test/york_21369.xml,https://dlib.york.ac.uk,/home/dlib/mapping_files/exam_col_mapping.txt]
def migrate_exam(path, content_server_url, collection_mapping_doc_path, user) 
	result = 1 # default is fail
	mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . (app one is not namespaced)
	common = CommonMigrationMethods.new
	puts "migrating  exam with content url"	
	foxmlpath = path.to_s		
	# enforce  UTF-8 compliance when opening foxml file
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
	# doesnt resolve nested namespaces, this fixes that
    ns = doc.collect_namespaces	
	# stage 1 to establish parent collection - map old to new from mappings file
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
	
	# find the max EXAM_PAPER version. no variants on this
	exam_paper_nums = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/foxml:datastreamVersion/@ID",ns)	
	idstate = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/@STATE",ns)  
	#if EXAM_PAPER state isnt active, stop processing and return error result code
	if !(idstate.to_s == "A")	
		puts " EXAM_PAPER state not active"
		return result  #default value is 1 until is changed after success
	end	
	
	exam_paper_all = exam_paper_nums.to_s
	exam_paper_current = exam_paper_all.rpartition('.').last 
	currentExamPaperVersion = 'EXAM_PAPER.' + exam_paper_current
	# GET CONTENT - get the location of the pdf as a string
	pdf_loc = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/foxml:datastreamVersion[@ID='#{currentExamPaperVersion}']/foxml:contentLocation/@REF",ns).to_s	
	#if EXAM_PAPERlocation isnt found, stop processing and return error result code
	if pdf_loc.length <= 0
        puts 	"couldnt get the pdf location"
		result = 1 
	return result
	end	
	#establish permissions from ACL datastream before setting in object. set a variable accordingly for easy reference 
	#throughout class
	# find max ACL version
	acl_nums = doc.xpath("//foxml:datastream[@ID='ACL']/foxml:datastreamVersion/@ID",ns)	
	acl_all = nums.to_s
	acl_current = all.rpartition('.').last 
	acl_currentVersion = 'ACL.' + current
	#get access value for user 'york'
	yorkaccess = doc.xpath("//foxml:datastream[@ID='ACL']/foxml:datastreamVersion[@ID='#{acl_currentVersion}']/foxml:xmlContent/acl:container/acl:role[@name='york']/text()",ns).to_s   
	
	# CONTENT FILES
	# this has local.fedora.host, which will be wrong. need to replace this with whereever they will be sitting 
	# reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	# needs to read (for development purposes on real machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	#and the content_server_url is set in the parameters :-)
	externalpdfurl = pdf_loc.sub 'http://local.fedora.server', content_server_url 
    externalpdflabel = "EXAM_PAPER"  #default
	# label needed for gui display
	label = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/foxml:datastreamVersion[@ID='#{currentExamPaperVersion}']/@LABEL",ns).to_s 
	if label.length > 0
		externalpdflabel = label #in all cases I can think of this will be the same as the default, but just to be sure
	end
	#these wont have the same name.need to search for them. ri search?
	# hash for any additional files that may emerge. may not be any. leave in for present. needs to be done here rather than later to ensure we obtain overridden version of FileSet class rather than CC as local version not namespaced
    additional_filesets = {}
	additional_file_set_number = 0
	elems = doc.xpath("//foxml:datastream[@ID]",ns)
	elems.each { |id| 
		idname = id.attr('ID')
		if ( idname.start_with?('EXAM_PAPER_ADDITIONAL') || (idname.match(/^EXAM_PAPER[1-9]/) ) )
			#ok, now need to find the latest version 
			version_nums = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion/@ID",ns)
			current_version_num = version_nums.to_s.rpartition('.').last
			current_version_name = idname + "." + current_version_num
			addit_file_loc = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/foxml:contentLocation/@REF",ns).to_s
			addit_file_loc = addit_file_loc.sub 'http://local.fedora.server', content_server_url
			fileset = Object::FileSet.new
			fileset.filetype = 'externalurl'
			fileset.external_file_url = addit_file_loc
			fileset.title = [idname]
			# may have a label - needed for display-  that is different to the datastream title
			label = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/@LABEL",ns).to_s 
			#dont standardise the labels, keep the original labels
			if label.length > 0
				fileset.label = label
			else
				fileset.label = "EXAM_PAPER_ADDITIONAL" #give it a default label
			end #end check of label length
			fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			fileset.depositor = user
			additional_filesets[idname] = fileset
		end #end check of idname
	 } #should be end of foreach loop	
		
	# create a new exam_paper implementing the dlibhydra models
	exam = Object::ExamPaper.new
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
	if yorkaccess == 'DENY'
	exam.permissions = [Hydra::AccessControls::Permission.new({:name=> "admin", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	else
		exam.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	end 
	exam.depositor = user
	
	# start reading and populating  data
	title =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	#title = t[0]
	title = title.to_s
	title.gsub!("&amp;","&")
	title = title 
	puts "title is" + title
	exam.title = [title]	# 1 only	
	# thesis.preflabel =  thesis.title[0] # skos preferred lexical label (which in this case is same as the title. 1 0nly but can be at same time as title 
	#better than using dc:identifier as this element is not always present in older records
	former_id = doc.xpath("//foxml:digitalObject/@PID",ns).to_s   
	exam.former_id = [former_id]
	# could really do with a file to list what its starting work on as a cleanup tool. doesnt matter if it doesnt get this far as there wont be anything to clean up
	tname = "exam_tracking.txt"
	trackingfile = File.open(tname, "a")
	trackingfile.puts( "am now working on " + former_id + " title:" + title )
	trackingfile.close	
	#creator
	#this needs to consult the authority list as it will be a department
	 creator = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns).to_s
		
	 #if the creator is empty we should try for publisher - a few older ones have this instead of creator
	 if !(creator.length > 0)
		creator = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:publisher/text()",ns).to_s
	 end
	 #keep this specific to exam papers in case it occurs in other types of record
	 #where the originating department may not be Biology
	if creator.length > 0 
		if
			creator == "OCR" || creator == "AQA" || creator == "Edexcel"
			creator = "biology" #just keep it to the minimal searchterm
		end
		if
			creator.include? "Making Faces" 
			creator = "history of art" #just keep it to the minimal searchterm
		end
		dept_preflabels = common.get_department_preflabel(creator)
		if dept_preflabels.empty?
			puts "no department found"
		end
		dept_preflabels.each do | preflabel|
			id = common.get_resource_id('department', preflabel)
			exam.creator_resource_ids = [id]	 
		end
	 end
	
	#module code will be got by the dc:identifier that doesnt start with 'york'
	#check if there is any authorty lookup for this?????????????????   #KALE    actual concepts dont seem to be ready yet -Cant so far see any csv or yml file present to generate these from, or code in tasks to create objects so think have just been listed in models  as "like to haves" 
	dcids = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:identifier/text()",ns).each do |dcid|
		dcids.push(dcid.to_s)
	end
	
	dcids.each do |dc_identifier|
	if (!dc_identifier.start_with?('york:') )		
			exam.module_code += [dc_identifier.strip]		
		end	
	end
	
	
	
	#FORMAT???? not in existingExamPaper model but listed as concept/lookup in data model. but actual concepts dont seem to be ready yet - cant see any csv or yml file present to generate these from or code in tasks to create objects so think have just been listed in models  as "like to haves"
	#also looks as if ExamPaper model needs an attribute adding for dc:format (and presumably the solr indexing model too, plus html.erb, forms  etc
	#format = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:format/text()",ns).to_s
	#add to ExamPaper when attribute has been included
	#confirmed with Ilka the format is no longer required to be migrated into the new records as in the case of exam papers this is always PDF/A
    #if format.length > 0
	#format = format.strip
	#	exam.format = [format]
	#end
	#qualification_name and level
	#not all records contain this data so test for presence
	#is found in dc:type as there is no publisher elelement
	# qualification level, name, resource type
	typesToParse = []  #
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns).each do |t|	
		if t.to_s.strip == "Master of Science (MSc), Master of Mathematics (MMath)"
			typesToParse.push("Master of Science (MSc)")
			typesToParse.push("Master of Mathematics (MMath)")
		else
			typesToParse.push(t)
		end
	end
	
	# qualification names (object)
	#this now needs to handle multiple qualifications   #KALE  TODO
	#however it is also possible that there wil not be a qualification name given
	qualification_name_preflabels = common.get_qualification_name_preflabel(typesToParse)
	
	 qualification_name_preflabels.each do |q|

		qname_id = common.get_resource_id('qualification_name',q.to_s)
			exam.qualification_name_resource_ids+=[qname_id]
	end	
	
	# qualification levels (yml file). multiples possible? allow for this case - may be some common modules
	typesToParse.each do |t|	  #CHOSS
	type_to_test = t.to_s
	qual_levels = common.get_qualification_level_term(type_to_test)  
	qual_levels.each do |ql|	
		exam.qualification_level += [ql]
	end

	# now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
	# resource Types map to dc:subject. at present the only official value is Dissertations, Academic
	#at present this should never return positive on the exam papers, the only type held is for theses dissertations (see \lib\assets\lists\subjects.csv
	#should something be added for exams? no element added in data model yet
	exams = [ 'theses','Theses','Dissertations','dissertations' ] 
	if exams.include? type_to_test	
	# not using methods below yet - or are we? subjects[] no longer in model
		subject_id = get_resource_id('subject',"Dissertations, Academic")
		exams.subject_resource_ids +=[subject_id]		 
	end
end	
    # existing yodl exam records do not include any language data, but content team say safe to make the assumpion
	#it will always be english
	
	# this should return the key as that allows us to just search on the term
	#exams will always be english
	standard_language = common.get_standard_language("English")#capitalise first letter		
	exam.language+=[standard_language]	
		
	
	#dc:description
	description = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:description/text()",ns).each do |s|
		description.push(s.to_s)
	end
	description.each do |s|
		exam.description+=[s]
	end	
	
	# I am going to migrate this data element even though metadata team dont think it is neccesary because "once theyre gone, theyre gone" - we do not have to actually display these in the interface if we choose not to, however if it later appears there is a need for them after all, we still have them!
	# dc.keyword (formerly subject, as existing ones from migration are free text .
	exam_subjects = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
	exam_subjects.push(s.to_s)
	end
	#subjects in dc are keywords in samvera model
	exam_subjects.each do |s|
		s.gsub!("&amp;","&")
		exam.keyword+=[s]   
	end	
	
	#date  (date of exam) [0,1]
	date = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:date/text()",ns).each do |s|
		date.push(s.to_s)
	end
	date.each do |d|
		exam.date+=[d]
	end	
	
	# rights.	
	# rights holder 0...1
	# checked data on dlib. all have the same rights statement and url cited, so this should work fine, as everything else is rights holders   
   exam_rightsholder = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[not(contains(.,'http')) and not (contains(.,'licenses')) ]",ns).to_s
   if exam_rightsholder.length > 0
	exam.rights_holder=[exam_rightsholder] 
   end
   
	# license  set a default which will be overwritten if one is found. its the url, not the statement. use licenses.yml not rights_statement.yml
	# For full york list see https://dlib.york.ac.uk/yodl/app/home/licences. edit in rights.yml
	defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
	exam_rights = defaultLicence
	exam_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
	
	newrights =  common.get_standard_rights(exam_rights)	
		if newrights.length > 0
		exam_rights = newrights
			exam.rights=[exam_rights]			
		end	
		
	#check the collection exists before saving and putting in collection
	# save	
	if Object::Collection.exists?(parentcol.to_s)
		exam.save!
		id = exam.id
		puts "exam id was " +id 
		puts "parent col was " + parentcol.to_s
		col = Object::Collection.find(parentcol.to_s)
		puts "id of col was:" +col.id
		puts " collection title was " + col.title[0].to_s
		col.members << exam  
		col.save!
	else
		puts "couldnt find collection " + parentcol.to_s
		return
	end
	
		
	# this is the section that keeps failing
	users = Object::User.all #otherwise it will use one of the included modules
	user = users[0]
	begin
		# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
		mfset.filetype = 'externalurl'
		mfset.title = ["EXAM_PAPER"]	#needs to be same label as content file in foxml 
		mfset.label = externalpdflabel
		# add the external content URL
		mfset.external_file_url = externalpdfurl
		actor = CurationConcerns::Actors::FileSetActor.new(mfset, user)
		actor.create_metadata(exam)
		#Declare file as external resource
        Hydra::Works::AddExternalFileToFileSet.call(mfset, externalpdfurl, 'external_url')
		if yorkaccess == 'DENY'
			mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "admin", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
		else
			mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
		end 
		exam.depositor = user
		mfset.depositor = user
		mfset.save!
		puts "fileset " + mfset.id + " saved"
    
	  # CHOSS this is here because the system tended to lock up during multiple uploads - suspect competition for resources or threading issue somewhere
		sleep 5 				
		 exam.mainfile << mfset
		sleep 5  
		 exam.save!
		 
	rescue
	    puts "QUACK QUACK OOPS! addition of external file unsuccesful"
		result = 1
		return result
		
   end   
     puts "all done for external content mainfile " + id  


# process external EXAM_ADDITIONAL files (not edited for exams, just keeping for reference)
for key in additional_filesets.keys() do		
		additional_exam_file_fs = additional_filesets[key]		
		#add metadata to make fileset appear as a child of the object
        actor = CurationConcerns::Actors::FileSetActor.new(additional_exam_file_fs, user)
        actor.create_metadata(exam)
		#Declare file as external resource
		url = additional_exam_file_fs.external_file_url
        Hydra::Works::AddExternalFileToFileSet.call(additional_exam_file_fs, url, 'external_url')
        additional_exam_file_fs.save!
		exam.members << additional_exam_file_fs
        exam.save!
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
