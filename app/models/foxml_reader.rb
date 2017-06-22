# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

#methods to create the  collection structure and do migrations
class FoxmlReader
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra



=begin
*the list of possible collections under theses is quite extensive - get it from an risearch query
*thesescollections.txt contains all the returned data from risearch for all levels
*thesescollectionsLevel2|3.txt is a complete cleaned up list of level 2|3 collections ready for use. 
*format is: old pid of collection,title of collection,old parent_pid
*col_mapping.txt is output by the script and is the permanent mapping file. format:
originalpid, title, newid . 
made the path to the various files used for this a parameter 
at present gonna use "/home/ubuntu/mapping_files/"  (with end slash)
so call is like rake migration_tasks:make_collection_structure[/home/ubuntu/mapping_files/]
=end

def make_collection_structure(mapping_path)
puts "running make_collection_structure"
mapping_file = mapping_path +"col_mapping.txt"
#make the top Theses level first, with a CurationConcerns (not dlibhydra) model.
#array of lines including title
topmapping = []
#we also need a pid:id hash so we can extract id via a pid key
idmap ={}
toppid = "york:18179"    #top level collection
topcol = Object::Collection.new
topcol.title = ["Masters dissertations"]
topcol.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
topcol.depositor = "ps552@york.ac.uk"
topcol.save!
topcol_id = topcol.id.to_s
puts "topcol.id was " +topcol.id
mappings_string = toppid + "," +  + topcol.title[0].to_s + "," + topcol_id 
	topmapping.push(mappings_string) 
#write to file as  permanent mapping that we can use when mapping theses against collections 
#open("/vagrant/files_to_test/col_mapping.txt", "a+")do |mapfile|
open(mapping_file, "a+")do |mapfile|
mapfile.puts(topmapping)
end

=begin
now we need to read from the list which I will create, splitting into appropriate parts and for each create an id and add it to the top level collection
=end
#hardcode second level file, but could pass in as param
#csv_text = File.read("/vagrant/files_to_test/thesescollectionsLevel2SMALL.txt")
level2file = mapping_path + "thesescollectionsLevel2.txt"
csv_text = File.read(level2file)
#csv_text = File.read("/vagrant/files_to_test/thesescollectionsLevel2.txt")
csv = CSV.parse(csv_text)
#we also need a file we can write to, as a permanent mapping
mappings_level2 = []

puts "starting second level(subjects)"
csv.each do |line|
    puts line[0]
	col = Object::Collection.new
	#col = Dlibhydra::Collection.new
	col.title = [line[1]]
	col.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	col.depositor = "ps552@york.ac.uk"
	col.save!
	col_id = col.id.to_s
	puts "subject col id was" + col_id
	topcol.members << col
	topcol.save!
	mappings_string = line[0] + "," +  + line[1] + "," + col_id 
	mappings_level2.push(mappings_string)
	#add to hash, old pid as key, new id as value
	key = line[0]	
	idmap[key] = col.id
end

#write to file as  permanent mapping that we can use when mapping theses against collections
open(mapping_file, "a+")do |mapfile| 
#open("/vagrant/files_to_test/col_mapping.txt", "a+")do |mapfile|
	mapfile.puts(mappings_level2)
end

#but we still have our mappings array, so  now use this to make third level collections
#best make a small list first

#centre for medievaL STUDDIES 
#york:806625  1969
#york:803772 1971
#MANAGEMENT
#york:795992 2009/2010
#york:795676 2010/2011

sleep 5 # wait 5 seconds before moving on to allow 2nd level collections some time to index before the level3s start trying to find them

#read in third level file
mappings_level3 = []
#csv_text3 = File.read("/vagrant/files_to_test/thesescollectionsLevel3SMALL.txt")
level3collsfile = mapping_path + "thesescollectionsLevel3.txt"
csv_text3 = File.read(level3collsfile)
#csv_text3 = File.read("/vagrant/files_to_test/thesescollectionsLevel3.txt")
csv_level3 = CSV.parse(csv_text3)

yearpidcount = 1
puts "starting third level (years)"
csv_level3.each do |line|
yearpidcount = yearpidcount +1
    puts "starting number " +yearpidcount.to_s+ " in list"
    puts line[0]
	year_col = Object::Collection.new
	puts "started new year collection"
	#col = Dlibhydra::Collection.new extend cc collection instead
	year_col_title = line[1].to_s
	puts "got level 3 title which was " +year_col_title
	year_col.title =  [year_col_title]
	year_col.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	year_col.depositor = "ps552@york.ac.uk"
	puts "saved permissions and depositor for year collection"
	year_col.save!
	puts "saved collection"
	year_col_id = year_col.id.to_s
	puts "year col id was " + year_col_id
	##need to find the right parent collection here	
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

#and write to permanent mapping file - these can be all the same whether level 2 or 3 or  1
#but test first with different
open(mapping_file, "a+")do |mapfile|
#open("/vagrant/files_to_test/col_mapping.txt", "a+")do |mapfile|
#open("/vagrant/files_to_test/col_mapping_lev3.txt", "a+")do |mapfile|
	mapfile.puts(mappings_level3)
end

puts "done"
=begin
#information we need for each collection is the old pid as a key, plus its parent pid, plus the collection name and the new id once it is created
top level will be the top level theses ie current Masters Dissertations (york:18179). 
second level  is discipline eg Archaeology, Education etc
OPTIONAL third level is year eg 1973. Not all disciplines have this level
=end

end  #of method

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
coll.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
coll.depositor = "ps552@york.ac.uk"
coll.title = [title]

coll.save!
child_id = coll.id
puts "collection id was " +child_id
parent_col = Object::Collection.find(parent_id)	
	puts "id of col was:" +parent_col.id
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


#this is defined in yaml
#return standard term from approved authority list
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

#this returns the  correct preflabels to be used when calling get_resource_id to get the object ref for the department
#note there may be more than one! hence the array - test for length
#its a separate method as multiple variants map to the same preflabel/object. 'loc' is the  
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

#this returns the  correct preflabel to be used when calling get_resource_id to get the object ref for the degree
#its a separate method as multiple variants map to the same preflabel/object. it really can only have one return - anything else would be nonsense. its going to be quite complex as some cross checking accross the various types may be  needed
#type_array will be an array consisting of all the types for an object!
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

#will need to expand this for other collections, but not Theses, as all have smae rights
def get_standard_rights(searchterm)
if searchterm.include?("yorkrestricted")
  term = 'York Restricted'
end
	auth = Qa::Authorities::Local::FileBasedAuthority.new('licenses') 
	rights = auth.search(term)[0]['id']
end





#bundle exec rake migration_tasks:migrate_lots_of_theses[/vagrant/files_to_test/app3fox,/vagrant/files_to_test/col_mapping.txt
# rake migration_tasks:migrate_lots_of_theses[/home/ubuntu/testfiles/foxml,/home/ubuntu/testfiles/foxdone,/home/ubuntu/mapping_files/col_mapping.txt]
#try this. will need to restart rails first.
def migrate_lots_of_theses(path_to_fox, path_to_foxdone, collection_mapping_doc_path)
puts "doing a bulk migration"
fname = "tally.txt"
tname = "tracking.txt"
#could really do with a file to list what its starting work on as a debug tool
trackingfile = File.open(tname, "a")
tallyfile = File.open(fname, "a")
Dir.foreach(path_to_fox)do |item|	
	#we dont want to try and act on the current and parent directories
	next if item == '.' or item == '..'
	trackingfile.puts( "now working on " + item)
	itempath = path_to_fox + "/" + item
	#migrate_thesis(itempath,collection_mapping_doc_path)
	result = 2  #so this wont do the actions required if it isnt reset
	begin
		result = migrate_thesis(itempath,collection_mapping_doc_path)
	rescue
		result = 1	
		tallyfile.puts("rescue says FAILED TO INGEST "+ itempath)  
	end
	if result == 0
		tallyfile.puts("ingested "+ itempath)
		#sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
		FileUtils.mv(itempath, path_to_foxdone + "/" + item)  #move files once migrated
	elsif result == 1   #this may well not work, as it may stop part way through before it ever gets here. rescue block might help?
		tallyfile.puts("FAILED TO INGEST "+ itempath)
		sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
	else
        tallyfile.puts " didnt return expected value of 0 or 1 "	
	end
end
tallyfile.close
trackingfile.close
end


#bundle exec rake migrate_thesis[/vagrant/files_to_test/york_847953.xml,9s1616164]
# bundle exec rake migrate_thesis[/vagrant/files_to_test/york_21031.xml,9s1616164]
#def migrate_thesis(path,collection)
#bundle exec rake migrate_thesis[/vagrant/files_to_test/york_21031.xml,/vagrant/files_to_test/col_mapping.txt]
#emotional world etc
#bundle exec rake migrate_thesis[/vagrant/files_to_test/york_807119.xml,/vagrant/files_to_test/col_mapping.txt]   
#bundle exec rake migration_tasks:migrate_thesis[/vagrant/files_to_test/york_847953.xml,/vagrant/files_to_test/col_mapping.txt]
#bundle exec rake migration_tasks:migrate_thesis[/vagrant/files_to_test/york_847943.xml,/vagrant/files_to_test/col_mapping.txt]
#on megastack: # rake migration_tasks:migrate_thesis[/home/ubuntu/testfiles/foxml/york_xxxxx.xml,/home/ubuntu/mapping_files/col_mapping.txt]
def migrate_thesis(path,collection_mapping_doc_path)
#mfset = Dlibhydra::FileSet.new   #FILESET. #defin this at top because otherwise expects to find it in CurationConcerns module 
result = 1 #default is fail
mfset = Object::FileSet.new   #FILESET. #define this at top because otherwise expects to find it in CurationConcerns module . 

puts "migrating a thesis"	
	foxmlpath = path	
	#enforce  UTF-8 compliance when opening foxml file
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
	#doesnt resolve nested namespaces, this fixes that
    ns = doc.collect_namespaces	
	
	#establish parent collection - map old to new from mappings file
	collection_mappings = {}
	mapping_text = File.read(collection_mapping_doc_path)
	csv = CSV.parse(mapping_text)
	csv.each do |line|    
		old_id = line[0]
		new_id = line[2]		
		collection_mappings[old_id] = new_id
	end
	
	
	#now see if the collection mapping is in here
	#make sure we have current rels-ext version
	rels_nums = doc.xpath("//foxml:datastream[@ID='RELS-EXT']/foxml:datastreamVersion/@ID",ns)	
	rels_all = all = rels_nums.to_s
	current_rels = rels_all.rpartition('.').last 
	rels_current_version = 'RELS-EXT.' + current_rels
	untrimmed_former_parent_pid  = doc.xpath("//foxml:datastream[@ID='RELS-EXT']/foxml:datastreamVersion[@ID='#{rels_current_version}']/foxml:xmlContent/rdf:RDF/rdf:Description/rel:isMemberOf/@rdf:resource",ns).to_s	
	#remove unwanted bits 
	former_parent_pid = untrimmed_former_parent_pid.sub 'info:fedora/york', 'york'
	parentcol = collection_mappings[former_parent_pid]
	#find max dc version
	nums = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/@ID",ns)	
	all = nums.to_s
	current = all.rpartition('.').last 
	currentVersion = 'DC.' + current
	
	#find the max THESIS_MAIN version
	thesis_nums = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion/@ID",ns)	
	thesis_all = thesis_nums.to_s
	thesis_current = thesis_all.rpartition('.').last 
	currentThesisVersion = 'THESIS_MAIN.' + thesis_current
	#GET CONTENT - get the location of the pdf as a string
	pdf_loc = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion[@ID='#{currentThesisVersion}']/foxml:contentLocation/@REF",ns).to_s	
	
	# CONTENT FILES
	#this has local.fedora.host, which will be wrong. need to replace this 
	#reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	#needs to read (for development purposes on real machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	newpdfloc = pdf_loc.sub 'local.fedora.server', 'yodlapp3.york.ac.uk'
	localpdfloc = pdf_loc.sub 'http://local.fedora.server', '/home/ubuntu/testfiles/content' #this will be added to below
    #ADDED 14th June for base name**********************************************************	
	basename = File.basename(localpdfloc)
	#comment out line below if redirecting to external url rather than ingesting local
	localpdfloc = '/home/ubuntu/testfiles/content/'+ basename  #not a repeat but an addition
	#end of addition*****************************	
	
	#dont continue to migrate file if content file not found
	if !File.exist?(localpdfloc)
		puts 'content file ' + localpdfloc.to_s + ' not found'	
		return
	else
		puts 'checked for ' + localpdfloc.to_s + ' found it present'
	end 
	#for initial development purposes on my machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
		
	
	#create a new thesis implementing the dlibhydra models
	thesis = Object::Thesis.new
#trying to set the state but this doesnt seem to be the way - the format  #<ActiveTriples::Resource:0x3fbe8df94fa8(#<ActiveTriples::Resource:0x007f7d1bf29f50>)> obviuously referenes something in a dunamic away
#which is different for each object
=begin
	existing_state = "didnt find an active state" 
	existing_state = doc.xpath("//foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state']/@VALUE",ns)
	puts '***************existing state:' + existing_state.to_s
	if existing_state.to_s == "Active"
	puts '***************FOUND existing state:' + existing_state.to_s
	#pasted in from gui produced Thesis! not sure if required
	 thesis.state = "http://fedora.info/definitions/1/0/access/ObjState#active"  
	end
=end
	#once depositor and permissions defined, object can be saved at any time
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	thesis.depositor = "ps552@york.ac.uk"
	
	#start reading and populating  data
	titleArray =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	t = titleArray.to_s   
	thesis.title = [t]	#1 only	
	#thesis.preflabel =  thesis.title[0] # skos preferred lexical label (which in this case is same as the title. 1 0nly but can be at same time as title 
	former_id = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:identifier/text()",ns).to_s
	if former_id.length > 0
	thesis.former_id = [former_id]
	end
	 creatorArray = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns).to_s
	 thesis.creator_string = [creatorArray.to_s]
	
	#abstract is currently the description. optional field so test presence
	thesis_abstract = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:description/text()",ns).to_s
	if thesis_abstract.length > 0
	thesis.abstract = [thesis_abstract] #now multivalued
	end
	
	#date_of_award (dateAccepted in the dc created by the model) 1 only
	thesis_date = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:date/text()",ns).to_s
	thesis.date_of_award = thesis_date
	#advisor 0... 1 so check if present
	thesis_advisor = []
	   doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:contributor/text()",ns).each do |i|
		thesis_advisor.push(i.to_s)
	end
	thesis_advisor.each do |c|
		thesis.advisor_string.push(c)
	end	
   #departments and institutions 
   locations = []
	 doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:publisher/text()",ns).each  do |i|
	 locations.push(i.to_s)
	 end
	 inst_preflabels = []
	 locations.each do |loc|
		#awarding institution id (just check preflabel here as few options)
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
				
		#department
		dept_preflabels = get_department_preflabel(loc)		 
		if dept_preflabels.empty?
			puts "no department found"
		end
		dept_preflabels.each do | preflabel|
			id = get_resource_id('department', preflabel)
			thesis.department_resource_ids +=[id]
		end
	end
	
	
	#qualification level, name, resource type
	typesToParse = []  #
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns).each do |t|	
	typesToParse.push(t)
	end
	#qualification names (object)
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
	#qualification levels (yml file). there can only be one
	typesToParse.each do |t|	
	type_to_test = t.to_s
	degree_level = get_qualification_level_term(type_to_test)
	if degree_level != "unfound"
		thesis.qualification_level += [degree_level]
	end

	#now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
	#resource Types map to dc:subject. at present the only official value is Dissertations, Academic
	theses = [ 'theses','Theses','Dissertations','dissertations' ] 
	if theses.include? type_to_test	
	#not using methods below yet - or are we? subjects[] no longer in model
		subject_id = get_resource_id('subject',"Dissertations, Academic")
		thesis.subject_resource_ids +=[subject_id]		 
	end
end	
	thesis_language = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:language/text()",ns).each do |lan|
	thesis_language.push(lan.to_s)
	end
	#this should return the key as that allows us to just search on the term
	thesis_language.each do |lan|   #0 ..n
	standard_language = "unfound"
	    standard_language = get_standard_language(lan.titleize)#capitalise first letter
		if standard_language!= "unfound"
			thesis.language+=[standard_language]
		end
	end	
	
	#dc.keyword (formerly subject, as existing ones from migration are free text not lookup
	thesis_subject = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
	thesis_subject.push(s.to_s)
	end
	thesis_subject.each do |s|
		thesis.keyword+=[s]   #TODO::THIS WAS ADDED TO FEDORA AS DC.RELATION NOT DC(OR DC11).SUBJECT!!!
	end	
	#dc11.subject??? not required for migration - see above
		
	#rights.	
	#rights holder 0...1
	#checked data on dlib. all have the same rights statement and url cited, so this should work fine, as everything else is rights holders   
   thesis_rightsholder = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[not(contains(.,'http')) and not (contains(.,'licenses')) ]",ns).to_s
   if thesis_rightsholder.length > 0
	thesis.rights_holder=[thesis_rightsholder] 
   end

	#license  set a default which will be overwritten if one is found. its the url, not the statement. use licenses.yml not rights_statement.yml
	#For full york list see https://dlib.york.ac.uk/yodl/app/home/licences. edit in rights.yml
	defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
	thesis_rights = defaultLicence
	thesis_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
	
	newrights =  get_standard_rights(thesis_rights)#  all theses currently York restricted 	
		if newrights.length > 0
		thesis_rights = newrights
			thesis.rights=[thesis_rights]			
		end	
		
	
	#save	
	thesis.save!
	id = thesis.id
	puts "thesis id was " +id 
	#put in collection	
	col = Object::Collection.find(parentcol.to_s)	
	puts "id of col was:" +col.id
	puts " collection title was " + col.title[0].to_s
	col.members << thesis  
	col.save!
	
	#this is the section that keeps failing
	begin
		# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
		users = Object::User.all #otherwise it will use one of the included modules
		user = users[0]	
		mfset.title = ["THESIS_MAIN"]	#needs to be same label as content file in foxml 
		mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
		mfset.depositor = "ps552@york.ac.uk"
		mfset.save!
	
		#THE NEXT FOUR LINES UPLOAD THE CONTENT INTO THE FILESET AND CREATE A THUMBNAIL
	
		local_file = Hydra::Derivatives::IoDecorator.new(File.open(localpdfloc, "rb"))	
		relation = "original_file"	
		fileactor = CurationConcerns::Actors::FileActor.new(mfset,relation,user)
		fileactor.ingest_file(local_file) #according to the documentation this method should produce derivatives as well
		mfset.save!	
	
		#THe NEXT TWO LINES ARE NEEDED TO ATTACH THE FILESET AND CONTENT TO THE WORK 
		actor = CurationConcerns::Actors::FileSetActor.new(mfset, user)
		actor.create_metadata(thesis)#name of object its to be added to #if you leave this out it wont create the metadata showing the related fileset
		#create_content does not seem to be required if we are using fileactor.ingest_file, and does not make any difference to download icon
		#actor.create_content(contentfile, relation = 'original_file' )
		#actor.create_content(contentfile) #15.03.2017 CHOSS
		#actor.create_content(local_file)
		#TELL THESIS THIS IS THE MAIN_FILE. assume this also sets mainfile_ids[]
    rescue
		puts "*****************UPLOAD DIDNT WORK FOR " + thesis.title[0].to_s + "********************************"    
		thesis.mainfile << mfset	   
		thesis.save!
		result = 1
		return result
   end
   #try explicitly cloing local_file and setting agents to nil so garbage will be collected
   #puts "now about to close file "
   #local_file.close   #doesnt seem to help
   #puts " closed local file "
   #fileactor = nil
   #puts "fileactor nilled"
   #actor = nil 
   #puts "actor nilled"
   #actor.nil
   #puts "files closed, actors nilled"
   puts "all done for file " + id
   result = 0
   return result   #give it  a return value
end
end #end of class
