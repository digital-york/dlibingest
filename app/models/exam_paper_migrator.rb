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
so call is like rake migration_tasks:make_exam_collection_structure[/home/dlib/mapping_files/].
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
topcol = populate_collection(toppid, topcol, foxpath)  #KALE
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
	col = populate_collection(line[0].strip, col, foxpath)  #KALE
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
	year_col = populate_collection(line[0].strip, year_col, foxpath)  #KALE
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
newrights =  get_standard_rights(coll_rights)#  all theses currently York restricted 	
if newrights.length > 0
	coll_rights = newrights	
end	
collection.rights=[coll_rights]
return collection
end  #end of populate_collection method

# this is defined in yaml
# return standard term from approved authority list
def get_qualification_level_term(searchterm)
masters = ['Masters','masters']
bachelors = ['Bachelors','Bachelor','Batchelors', 'Batchelor']
diplomas = ['Diploma','(Dip', '(Dip', 'Diploma (Dip)']
doctoral = ['Phd','Doctor of Philosophy (PhD)']
standardterm="unfound"
if masters.include? searchterm
	standardterm = 'Masters (Postgraduate)'
elsif bachelors.include? searchterm
	standardterm = 'Bachelors (Undergraduate)'
elsif diplomas.include? searchterm
	standardterm = 'Diplomas (Postgraduate)' #my guess
elsif doctoral.include? searchterm
    standardterm = 'Doctoral (Postgraduate)'	
end
if standardterm != "unfound"
	#pass the id, get back the term. in this case both are currently identical
	auth = Qa::Authorities::Local::FileBasedAuthority.new('qualification_levels')
	approvedterm = auth.find(standardterm)['term']
else 
	approvedterm = "unfound"
end
return approvedterm
end #end get_qualification_level_term

#this returns the  id of an value from  an authority list where each value is stored as a fedora object
#the parameters should be one of the authority types with a relevant class listed in Dlibhydra::Terms and the preflabel is the exact preflabel for the value (eg "University of York. Department of Philosophy") 
def get_resource_id(authority_type, preflabel)
id="unfound"
preflabel = preflabel.to_s
	if authority_type == "department"
		service = Dlibhydra::Terms::DepartmentTerms.new		 
	elsif authority_type == "qualification_name"
	    service = Dlibhydra::Terms::QualificationNameTerms.new
	elsif authority_type == "institution"  #not sure about this since we only have two? york and oxford brookes?
		service = Dlibhydra::Terms::CurrentOrganisationTerms.new
	elsif authority_type == "subject"   
	    service = Dlibhydra::Terms::SubjectTerms.new 
	elsif authority_type == "person_name"   #no pcurrent_person objects yet created
	    service = Dlibhydra::Terms::CurrentPersonTerms.new
	end
	id = service.find_id(preflabel)
end

# this returns the  correct preflabels to be used when calling get_resource_id to get the object ref for the department
# note there may be more than one! hence the array - test for length
# its a separate method as multiple variants map to the same preflabel/object. 'loc' is the  
def get_department_preflabel(stringtomatch)
preflabels=[]
=begin
Full list of preflabels at https://github.com/digital-york/dlibingest/blob/new_works/lib/assets/lists/departments.csv

and here is the equivalent list of dc:publisher from risearch (GET all values of dc:publisher for objects with type Theses  (make sure to tick Force Distinct")
select  $dept
 from <#ri>
 where $object <dc:type> 'Theses' 
and $object <dc:publisher> $dept)

note the variants - hence need to reduce the search strings to minimum and decapitalise
 
University of York. Dept. of History of Art
University of York. Dept. of Chemistry
University of York. Institute of Advanced Architectural Studies
Institute of Advanced Architectural Studies
University of York. York Management School
University of York. Dept. of Management Studies
University of York. Centre for Medieval Studies
University of York. Dept. of History
University of York. Dept. of Sociology
University of York. Dept. of Education
University of York. Dept. of Economics and Related Studies
University of York. Dept. of Music.
University of York. Dept. of Archaeology
University of York. Dept. of Biology
University of York. Dept. of Health Sciences
University of York. Dept. of English and Related Literature
University of York. Dept. of Language and Linguistic Science
University of York. Dept. of Politics
University of York. Dept. of Philosophy
University of York. Dept. of Social Policy and Social Work
"York Management School (York, England)"
University of York. Institute of Advanced Architectural Studies.
University of York. Centre for Conservation Studies
University of York. Department of Archaeology
University of York. Dept of Archaeology
niversity of York. Dept. of Archaeology
University of York: Dept. of Archaeology
University of York. Post-war Reconstruction and Development Unit
University of York. York Management School.
University of York. Centre for Medieval Studies.
University of York. The York Management School.
The University of York. York Management School.
University of York. York Management School'
University of York. Dept.of History of Art
University of York. Dept. of History of Art.
University of York. Dept of History of Art
University of York. Departments of English and History of Art
University of York. Centre for Eighteenth Century Studies
Oxford Brookes University    									#this is an awarding institution not a dept

=end
	loc = stringtomatch.downcase  #get ride of case inconsistencies
	if loc.include? "reconstruction"
		preflabels.push("University of York. Post-war Reconstruction and Development Unit") 
	elsif loc.include? "advanced architectural"
	    preflabels.push("University of York. Institute of Advanced Architectural Studies")
	elsif loc.include? "medieval"
	    preflabels.push("University of York. Centre for Medieval Studies")
	elsif loc.include? "history of art"
	    preflabels.push("University of York. Department of History of Art") 
	elsif loc.include? "conservation"
	    preflabels.push("University of York. Centre for Conservation Studies")
	elsif loc.include? "eighteenth century"
	    preflabels.push("University of York. Centre for Eighteenth Century Studies")
	elsif loc.include? "chemistry"
	    preflabels.push("University of York. Department of Chemistry")
	elsif loc.include? "history"   #ok because of order
	    preflabels.push("University of York. Department of History")
	elsif loc.include? "sociology"
	    preflabels.push( "University of York. Department of Sociology")
	elsif loc.include? "education"
	    preflabels.push("University of York. Department of Education")
	elsif loc.include? "economics and related"
	    preflabels.push( "University of York. Department of Economics and Related Studies")
	elsif loc.include? "music"
	    preflabels.push( "University of York. Department of Music")
	elsif loc.include? "archaeology"
	    preflabels.push( "University of York. Department of Archaeology")
	elsif loc.include? "biology"
	    preflabels.push( "University of York. Department of Biology")
	elsif loc.include? "english and related literature"
	    preflabels.push( "University of York. Department of English and Related Literature")
	elsif loc.include? "health sciences"
	    preflabels.push( "University of York. Department of Health Sciences")
	elsif loc.include? "politics"
	    preflabels.push("University of York. Department of Politics")
	elsif loc.include? "philosophy"
	    preflabels.push( "University of York. Department of Philosophy")
	elsif loc.include? "social policy and social work"
	    preflabels.push( "University of York. Department of Social Policy and Social Work")
	elsif loc.include? "management"
	    preflabels.push( "University of York. The York Management School")
	elsif loc.include? "language and linguistic science"
	    preflabels.push("University of York. Department of Language and Linguistic Science")
	elsif loc.include? "departments of english and history of art"   #damn! two departments to return!
	    preflabels.push( "University of York. Department of Department of English and Related Literature")
		preflabels.push("University of York. Department of Department of Language and Linguistic Science")
	end
	return preflabels
end

# this returns the  correct preflabel to be used when calling get_resource_id to get the object ref for the degree
# its a separate method as multiple variants map to the same preflabel/object. it really can only have one return - anything else would be nonsense. its going to be quite complex as some cross checking accross the various types may be  needed
# type_array will be an array consisting of all the types for an object!
def get_qualification_name_preflabel(type_array)

#Arrays of qualification name variants
artMasters = ['Master of Arts (MA)', 'Master of Arts', 'Master of Art (MA)', 'MA (Master of Arts)','Masters of Arts (MA)', 'MA']
artBachelors = ['Batchelor of Arts (BA)', '"Bachelor of Arts (BA),"', 'BA', 'Bachelor of Arts (BA)']
artsByResearch = ['Master of Arts by research (MRes)', '"Master of Arts, by research (MRes)"' ]
scienceByResearch = ['Master of Science by research (MRes)', '"Master of Science, by research (MRes)"' ]
scienceBachelors = ['Batchelor of science (BSc)', '"Bachelor of Science (BSc),"', 'BSc', ]
scienceMasters = ['Master of Science (MSc.)', '"Master of Science (MSc),"',"'Master of Science (MSc)",'Master of Science (MSc)','MSc', ]
philosophyBachelors = ['Bachelor of Philosophy (BPhil)', 'BPhil']
philosophyMasters = ['Master of Philosophy (MPhil)','MPhil']
researchMasters = ['Master of Research (Mres)','Master of Research (MRes)','Mres','MRes']#this is the only problematic one
#the variant single quote character in  Conservation Studies is invalid and causes invalid multibyte char (UTF-8) error so  handled this in nokogiri open document call. however we also need to ensure the resulting string is included in the lookup array so the match will still be found. this means recreating it and inserting it into the array
not_valid = "Postgraduate Diploma in ‘Conservation Studies’ (PGDip)"
valid_now = not_valid.encode('UTF-8', :invalid => :replace, :undef => :replace)
pgDiplomas = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', 'Postgraduate Diploma in Medieval Studies (PGDip)','PGDip', 'Diploma','(Dip', '(Dip', 'Diploma (Dip)', valid_now] 


qualification_name_preflabel = "unfound" #initial value
#by testing all we should find one of those below
type_array.each do |t,|	    #loop1
	type_to_test = t.to_s
	
	#outer loop tests for creation of qualification_name_preflabel
	if qualification_name_preflabel == "unfound"   #loop2
		if artMasters.include? type_to_test #loop2a
		 qualification_name_preflabel = "Master of Arts (MA)"		 
		elsif artBachelors.include? type_to_test
		 qualification_name_preflabel = "Bachelor of Arts (BA)"		 
		elsif artsByResearch.include? type_to_test
		 qualification_name_preflabel = "Master of Arts by Research (MRes)"		 
		elsif scienceBachelors.include? type_to_test
		 qualification_name_preflabel = "Bachelor of Science (BSc)"		 
		elsif scienceMasters.include? type_to_test
		 qualification_name_preflabel = "Master of Science (MSc)"		 
		elsif scienceByResearch.include? type_to_test
		 qualification_name_preflabel = "Master of Science by Research (MRes)"		 
	    elsif philosophyBachelors.include? type_to_test
		 qualification_name_preflabel = "Bachelor of Philosophy (BPhil)"		 
		elsif philosophyMasters.include? type_to_test
		 qualification_name_preflabel = "Master of Philosophy (MPhil)"		
		elsif pgDiplomas.include? type_to_test
		 qualification_name_preflabel = "Postgraduate Diploma (PGDip)"		 
		end #end loop2a
	end #end loop2
		
	#not found? check for plain research masters without arts or science specified (order of testing here is crucial)
		if qualification_name_preflabel == "unfound"    #loop3
			if researchMasters.include? type_to_test #loop 4 not done with main list as "MRes" may be listed as separate type as well as a more specific type
				qualification_name_preflabel = "Master of Research (MRes)"
			end#end loop 4
		end   #'end loop 3
	end #end loop1	
	return qualification_name_preflabel
end  #this is where the get_qualification_name_preflabel method should end

def get_standard_language(searchterm)
	s = searchterm.titleize
	auth = Qa::Authorities::Local::FileBasedAuthority.new('languages')
	approved_language = auth.search(s)[0]['id']
end

# will need to expand this for other collections, but not Theses, as all have smae rights
def get_standard_rights(searchterm)
puts "at get_standard_rights searchTeerm was " + searchterm
if searchterm.include?("yorkrestricted")
  term = 'York Restricted'
end
	auth = Qa::Authorities::Local::FileBasedAuthority.new('licenses') 
	rights = auth.search(term)[0]['id']
end





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
# trying to set the state but this doesnt seem to be the way - the format  #<ActiveTriples::Resource:0x3fbe8df94fa8(#<ActiveTriples::Resource:0x007f7d1bf29f50>)> obviuously referenes something in a dunamic away
# which is different for each object
=begin
	existing_state = "didnt find an active state" 
	existing_state = doc.xpath("//foxml:objectProperties/foxml:property[@NAME='fedora-system:def/model#state']/@VALUE",ns)
	puts '***************existing state:' + existing_state.to_s
	if existing_state.to_s == "Active"
	puts '***************FOUND existing state:' + existing_state.to_s
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
	begin
		# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
		users = Object::User.all #otherwise it will use one of the included modules
		user = users[0]	
		mfset.filetype = 'embeddedfile'
		mfset.title = ["THESIS_MAIN"]	#needs to be same label as content file in foxml 
		mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
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
