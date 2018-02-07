# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# some methods to create the  collection structure and do migrations
class UndergraduatePaperCollectionMigrator
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


end # end of class
