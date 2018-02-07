# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# methods to create the  collection structure and do Exam Paper migrations
class ExamPaperCollectionMigrator
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra


=begin
*the list of possible collections under exam papers is quite extensive - get it from  risearch querys, then find and replace to format
*format is: old pid of collection,title of collection,old parent_pid
 PHYSICS HAS AN ODD STRUCTURE. A 4th layer 
top level is york:21267 title is Exam Papers
second level listfile is  exam_colls_level2.txt
third level listfiles is exam_colls_level3.txt
fourth level (physics) listfiles is exam_colls_level4_physics.txt
*exam_col_mapping.txt is output by the script and is the permanent mapping file. format:
originalpid, title, newid . 
on dev server use "/home/dlib/mapping_files/"  (with end slash)
so call is like >rake migration_tasks:make_exam_collection_structure[/home/dlib/mapping_files/,/home/dlib/testfiles/foxml/,ps552@york.ac.uk].
=end

def say_hello
	puts "Hello sailor!"
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


end # end of class
