# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
#require 'rdf' #added this as an experiment to try to solve Dlibhydra problems
#require 'curation_concerns' #makes no difference
require 'dlibhydra'
require 'csv'

class FoxmlReader
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra

=begin
*list of possible collections under theses is quite extensive - get it from an risearch query
*thesescollections.txt contains all the returned data from risearch for all levels
*thesescollectionsLevel2|3.txt is a complete cleaned up list of level 2|3 collections ready for use. ~NO IT ISNT. IS ONLY PARTIAL
*format is: old pid of collection,title of collection,old parent_pid
*col_mapping.txt is output by the script and is the permanent mapping file. format:
originalpid, title, newid . seems to make sense
=end
#This code does work, but the level three list is incomplete - suspect the risearch was not run with unlimited results. so for real version would require running again - but for demo purposes I'v just deleted collections with only one. rerun risearch query with a complete list against yodlapp3 on monday (check the list of level 2 collections in the query before running, and check the number of returns)
def make_collection_structure
puts "running make_collection_structure"

#make the top Theses level first, with a CurationConcerns (not dlibhydra) model.
#array of lines including title
topmapping = []
#we also need a pid:id hash so we can extract id via a pid key
idmap ={}
toppid = "york:18179"
topcol = Object::Collection.new
#topcol = Dlibhydra::Collection.new
topcol.confirm_cc #confirms when I give Object as module it gets a CurationConcerns Collection
topcol.title = ["Masters dissertations"]
topcol.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
topcol.depositor = "ps552@york.ac.uk"
topcol.save!
topcol_id = topcol.id.to_s
puts "topcol.id was " +topcol.id
mappings_string = toppid + "," +  + topcol.title[0].to_s + "," + topcol_id 
	topmapping.push(mappings_string) 
#write to file as  permanent mapping that we can use when mapping theses against collections 
open("/vagrant/files_to_test/col_mapping.txt", "a+")do |mapfile|
	mapfile.puts(topmapping)
end

=begin
now we need to read from the list which I will create, splitting into appropriate parts and for each create an id and add it to the top level collection
=end
#hardcode second level file, but could pass in as param
#csv_text = File.read("/vagrant/files_to_test/thesescollectionsLevel2SMALL.txt")
csv_text = File.read("/vagrant/files_to_test/thesescollectionsLevel2.txt")
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
	puts "at line 56 " +key+ " was added to idmap_level2 with value " +col_id
	idmap[key] = col.id
end

#write to file as  permanent mapping that we can use when mapping theses against collections 
open("/vagrant/files_to_test/col_mapping.txt", "a+")do |mapfile|
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
csv_text3 = File.read("/vagrant/files_to_test/thesescollectionsLevel3.txt")
csv_level3 = CSV.parse(csv_text3)
yearpidcount = 1
puts "starting third level (years)"
csv_level3.each do |line|
yearpidcount = yearpidcount +1
    puts "starting number " +yearpidcount.to_s+ " in list"
    puts line[0]
	year_col = Object::Collection.new
	year_col.confirm_cc
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
	parent.confirm_cc
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
open("/vagrant/files_to_test/col_mapping.txt", "a+")do |mapfile|
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


def make_collection
#coll = Object::Collection.new
coll = Object::Collection.new
#coll.preflabel = "stuff I made"
coll.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
coll.depositor = "ps552@york.ac.uk"
coll.title = ["a collection made by ruby"]
#coll.preflabel = coll.title[0]  # doesnt work because models now require a preflabel but generic collection model doesnt have one. sure we can get round this but requires extra edits - see if were actually going to use preflabel before doing this!

coll.save!
id = coll.id
puts "collection id was " +id
end

#create a simple out of the box thesis in a collection and upload a test file to it to check the basic functions and calls work before integrating with dlibhydra
def vanilla
fset = FileSet.new
t = CurationConcerns::Thesis.create
t.title =["A spell to turn fine straw to gold"]
t.preflabel =t.title[0]
t.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
t.depositor = "ps552@york.ac.uk"
t.save!
col = Object::Collection.find("zk51vg76b")
col.members << t  
col.save!
users = Object::User.all #otherwise it will use one of the included modules
user = users[0]	
fset.title = [t.preflabel]
fset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
fset.depositor = "ps552@york.ac.uk"
contentfile = open("/vagrant/files_to_test/testpdf.pdf")
#contentfile = open("/vagrant/files_to_test/testcontentupload.txt")	
actor = CurationConcerns::Actors::FileSetActor.new(fset, user)
fset.save!
t.members << fset #could this be the critical bit?
#actor.create_metadata(t, file_set_params = {files: [contentfile],title: ['vanilla title'],visibility: 'public'})
actor.create_metadata(t)  #note 't' is name of thesis object, not content file
puts "metadata created"
#result = actor.create_content(contentfile)
result = actor.create_content(contentfile, relation = 'original_file' )
puts "original created"

puts "result was " +result.to_s
fset.save!
puts "done"
end

#with dlibhydra
def strawberry
fset = FileSet.new
#fset = CcMigrate::MainFileSet.new  #Cant use the MainFileSet. needs new child object instead.
dt = CurationConcerns::DlibThesis.create
#dt = CurationConcerns::Thesis.create
#dt.speak
dt.title = ["fresh strawberry with a small pdf file"]
dt.preflabel = dt.title[0]
dt.creator = ["fred smith"]
dt.abstract = "'It seems very pretty,' she said when she had finished it, 'but it's rather hard to understand!' (You see she didn't like to confess, even to herself, that she couldn't make it out at all.) 'Somehow it seems to fill my head with ideas—only I don't exactly know what they are! However, somebody killed something: that's clear, at any rate.'"
dt.date_of_award = "2012"
dt.advisor.push("Albert Einstein")
dt.department.push ("Department of Things") 
dt.awarding_institution = "University of Life"
dt.qualification_name = "Masters in Cunning"
dt.qualification_level = "Masters"
dt.subject.push("Dissertations, Academic")	
dt.language.push("Klingon")
dt.keyword.push("some_keyword")
dt.rights_holder = "The Kings Hand" 
#dt.license = "http://dlib.york.ac.uk/licences#yorkrestricted"
dt.rights = "http://dlib.york.ac.uk/licences#yorkrestricted"

#required permissions and depositor
dt.depositor = "ps552@york.ac.uk"
dt.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
dt.save!
col = Object::Collection.find("9s1616164")
col.members << dt  
col.save!
puts "made the strawberry"
#add the file
#users = Object::User.all #otherwise it will use one of the included modules
#user = users[0]	

#****now we have to make a child object to hold the generic file set and the content. generic work?
childobject  = Dlibhydra::GenericWork.create
childobject.title = ["thesis pdf"]
childobject.preflabel = childobject.title[0]
#dont add depositor or permissions, no methods in GenericWork for this

#read the content and put it into the fset
#contentfile = open("/vagrant/files_to_test/testcontentupload.txt")	
contentfile = open("/vagrant/files_to_test/testpdf.pdf") #only for pdf - says "KeyError: key not found: :object" but still seems to complete ok. huh? These could be derivatives errors. https://github.com/curationexperts/goldenseal/issues/242 and also https://github.com/projecthydra/hydra-works/issues/210
fset.title = ["thesis content"]
fset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
users = Object::User.all #otherwise it will use one of the included modules
user = users[0]
actor = CurationConcerns::Actors::FileSetActor.new(fset, user)
actor.create_metadata(dt)#name of object its to be added to
puts "crested metadata line 106"
result = actor.create_content(contentfile)
puts "created content line 108"
fset.save!
childobject.members << fset
childobject.save!

dt.members << childobject
puts "saved a generic object and added it to thesis" 
dt.save!

fset.title = ["thesis content"]
fset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
fset.depositor = "ps552@york.ac.uk"

#dt.members << fset #could this be the critical bit?
#actor.create_metadata(t, file_set_params = {files: [contentfile],title: ['vanilla title'],visibility: 'public'})
#puts "result was " +result.to_s
fset.save!
puts "added file to strawberry"
end



def test_pdf_upload
#make basic cc thesis
	#vt = CurationConcerns::Thesis.create
	vt = CurationConcerns::DlibThesis.create	
	vt.title = ["and a fourth CC vanilla thesis"]
	vt.preflabel = vt.title[0]   #no preflabel in vanilla CurationConcerns
	vt.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	vt.depositor = "ps552@york.ac.uk"
	vt.save!
puts "done"
#now try to upload a content file into a Dlibhydra fileset
	contentfile = open("/vagrant/files_to_test/testpdf.pdf")
	users = Object::User.all #otherwise it will use one of the included modules
	user = users[0]	
	vfset = FileSet.new
	#vfset = CcMigrate::MainFileSet.new   #SystemStackError: stack level too deep
	vfset.title = ["main pdf content"]
	#vfset.preflabel = "main pdf content"
	actor = CurationConcerns::Actors::FileSetActor.new(vfset, user)
puts "OK SO FAR"
actor.create_content(contentfile, relation = 'main_file' )
actor.create_metadata(vt, file_set_params = {files: [contentfile],
                                          title: ['test title'],
                                          visibility: 'public'})
puts "still ok"	
vfset.save!
vt.save!
puts "done"
end


def test_pdf_upload_VANILLA_WORKS
#make basic cc thesis
	vt = CurationConcerns::Thesis.create
	vt.title = ["ANOTHER CC vanilla thesis"]
	#vt.preflabel = vt.title[0]   #no preflabel in vanilla CurationConcerns
	vt.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	vt.depositor = "ps552@york.ac.uk"
	vt.save!
puts "done"
#now try to upload a content file
	contentfile = open("/vagrant/files_to_test/testpdf.pdf")
	users = Object::User.all #otherwise it will use one of the included modules
	user = users[0]	
	vfset = FileSet.new
	vfset.title = ["main pdf content"]
	actor = CurationConcerns::Actors::FileSetActor.new(vfset, user)
puts "OK SO FAR"
actor.create_content(contentfile, relation = 'main_file' )
actor.create_metadata(vt, file_set_params = {files: [contentfile],
                                          title: ['test title'],
                                          visibility: 'public'})
puts "still ok"	
end



def testme

puts "starting test of migration scripts"
t= Object::Thesis.create
t.title = ["my script made this thesis"]
t.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	t.depositor = "ps552@york.ac.uk"	
	#save	
	t.save!	
	id = t.id
	puts "thesis id was " +id 

end 


#5712m6524]
#for test purposes the path is /vagrant/files_to_test/york_847953.xml
# bundle exec rake migrate[/vagrant/files_to_test/york_847953.xml,qr46r0806]
# bundle exec rake migrate[/vagrant/files_to_test/york_807119.xml,qr46r0806] 
# bundle exec rake migrate[/vagrant/files_to_test/york_21031.xml,zk51vg76b] 


def migrate(path,collection)
mfset = FileSet.new   #FILESET. #defin this at top because otherwise expects to find it in CurationConcerns module 
puts "migrating"
	defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
	foxmlpath = path
	puts "path was " + foxmlpath
	parentcol = collection
	#TODO remember collection allocation will somehow need to be done appropraitely in new system - may not be the same way. may require getting from rels-ext then mapping against new list - or may be utterly different. will need discussion.
	
	#open foxml file, enforcing  UTF-8 compliance
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
	#doesnt resolve nested namespaces, this fixes that
    ns = doc.collect_namespaces	
	#find the max dc version
	#versions = Array[]
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
	puts "at line 362 found thesis doc " + pdf_loc #but this has local.fedora.host, which will be wrong. need to replace this 
	#reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	#needs to read (for development purposes on real machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	newpdfloc = pdf_loc.sub 'local.fedora.server', 'yodlapp3.york.ac.uk'
	#for initial development purposes on my machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	puts "edited pdf loc is :" + newpdfloc
	#create a new thesis implementing the dlibhydra models
	thesis = CurationConcerns::DlibThesis.create
	
	#start reading and populating  data
	titleArray =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	t = titleArray.to_s   #CHOSS - construct title!
	thesis.title = [t]	#1 only	
	thesis.preflabel =  thesis.title[0] # skos preferred lexical label (which in this case is same as the title. 1 0nly but can be at same time as title 
	##A thesis should only ever have one author (creator)	
	 creatorArray = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns).to_s
	 thesis.creator = [creatorArray.to_s]
	
	#abstract is currently the description. optional field so test presence
	thesis_abstract = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:description/text()",ns).to_s
	if thesis_abstract.length > 0
	thesis.abstract = thesis_abstract
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
		thesis.advisor.push(c)
	end	

   #departments and institutions (this gets wierd). need to do some data checking for splits etc. 
   #possible splits: York.  
   #without splits: Oxford Brookes University
   locations = []
	 doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:publisher/text()",ns).each  do |i|
	 locations.push(i.to_s)
	 end
	 locations.each do |loc|
		#first get the institution . 1 only. will overwrite if there
		#then add the department, splitting strings where required	
		if loc.include? "University of York"
			thesis.awarding_institution = "University of York"
			if loc.include? "York." 
				splitstring = loc.split('York.',2)#2nd param ensures it only splits into 2 parts
				thesis.department.push (splitstring[1])
			elsif loc.include? "York:"
				splitstring = loc.split('York:',2)
				thesis.department.push (splitstring[1])			
			end
	    elsif loc.include? "Institute of Advanced Architectural Studies"
			thesis.awarding_institution = "University of York"
			thesis.department.push ("Institute of Advanced Architectural Studies")
		elsif loc.include? "York Management School "
			thesis.awarding_institution = "University of York"
			thesis.department.push ("York Management School")        				
		elsif loc.include? "Oxford Brookes University"
			thesis.awarding_institution = "Oxford Brookes University"
		end
	end
	
	#work on this
	#qualification level, name, resource type
	# resource type should be added as a dc:subject 
	#ignore dcmi types
	typesToParse = []  #
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns).each do |t|	
	typesToParse.push(t)
	end
	#Arrays of qualification name variants
	artMasters = ['Master of Arts (MA)', 'Master of Arts', 'Master of Art (MA)', 'MA (Master of Arts)','Masters of Arts (MA)', 'MA']
	artBachelors = ['Batchelor of Arts (BA)', '"Bachelor of Arts (BA),"', 'BA', 'Bachelor of Arts (BA)']
	artsByResearch = ['Master of Arts by research (MRes)', '"Master of Arts, by research (MRes)"' ]
	scienceBachelors = ['Batchelor of science (BSc)', '"Bachelor of Science (BA),"', 'BSc', ]
	scienceMasters = ['Master of Science (MSc.)', '"Master of Science (MSc),"',"'Master of Science (MSc)",'Master of Science (MSc)','MSc', ]
	scienceByResearch  = ['Master of Science by research (MRes)']
	philosophyBachelors = ['Bachelor of Philosophy (BPhil)', 'BPhil']
	philosophyMasters = ['Master of Philosophy (MPhil)','MPhil']
	researchMasters = ['Master of Research (Mres)','Master of Research (MRes)','Mres','MRes']
	#the variant single quote character in  Conservation Studies is invalid and causes invalid multibyte char (UTF-8) eror so  handled this in nokogiri open document call. however we also need to ensure the resulting string is included in the lookup array so the match will still be found. this means recreating it and inserting it into the array
	not_valid = "Postgraduate Diploma in ‘Conservation Studies’ (PGDip)"
	valid_now = not_valid.encode('UTF-8', :invalid => :replace, :undef => :replace)
	conservationDiploma = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', valid_now]	
	medievalDiploma =['Postgraduate Diploma in Medieval Studies (PGDip)','PGDip']
	
	#degree levels - masters, batchelors, diploma
	masters = ['Masters','masters']
	bachelors = ['Bachelors','Bachelor','Batchelors', 'Batchelor']
	diplomas = ['Diploma','(Dip', '(Dip', 'Diploma (Dip)']
	
	#resource Types map to dc:subject. at present the only official value is Dissertations, Academic
	theses = [ 'theses','Theses','Dissertations','dissertations' ] 
	
	#now check which group (if any) is present and apply standard name
	typesToParse.each do |t|	
	type_to_test = t.to_s
	#check academic degree
	#this is now the vivo:AcademicDegree type in the model. it will be precisely one
		if artMasters.include? type_to_test
		 thesis.qualification_name = "Master of Arts (MA)"
		elsif artBachelors.include? type_to_test
		 thesis.qualification_name = "Bachelor of Arts (BA)"
		elsif artsByResearch.include? type_to_test
		 thesis.qualification_name = "Master of Arts by research (MRes)"
		elsif scienceBachelors.include? type_to_test
		 thesis.qualification_name = "Bachelor of Science (BSc)"
		elsif scienceMasters.include? type_to_test
		 thesis.qualification_name = "Master of Science (MSc)"
		elsif scienceByResearch.include? type_to_test
		 thesis.qualification_name = "Master of Science by research (MRes)"
	    elsif philosophyBachelors.include? type_to_test
		 thesis.qualification_name = "Bachelor of Philosophy (BPhil)"
		elsif philosophyMasters.include? type_to_test
		 thesis.qualification_name = "Master of Philosophy (MPhil)"
	    elsif researchMasters.include? type_to_test
		 thesis.qualification_name = "Master of Research (MRes)"
		elsif medievalDiploma.include? type_to_test
		 thesis.qualification_name = "Postgraduate Diploma in Medieval Studies (PGDip)"
		elsif conservationDiploma.include? type_to_test
		 thesis.qualification_name = "Postgraduate Diploma in Conservation Studies (PGDip)"
		end
		
	#now check for qualification levels. there can only be one
	if masters.include? type_to_test
		 thesis.qualification_level = "Masters"
	elsif bachelors.include? type_to_test
		 thesis.qualification_level = "Bachelors"
    elsif diplomas.include? type_to_test
		 thesis.qualification_level = "Postgraduate Diploma"
	end
	
	#now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
	if theses.include? type_to_test
		 thesis.subject.push("Dissertations, Academic")	
	end
end	
	
	
	thesis_language = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:language/text()",ns).each do |lan|
	thesis_language.push(lan.to_s)
	end
	thesis_language.each do |lan|   #0 ..n
		thesis.language.push(lan)
	end	
	
	#dc.keyword (formerly subject, as existing ones from migration are free text not lookup
	thesis_subject = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
	thesis_subject.push(s.to_s)
	end
	thesis_subject.each do |s|
	puts "found subject " +s.to_s
		thesis.keyword.push(s)   #TODO::THIS WAS ADDED TO FEDORA AS DC.RELATION NOT DC(OR DC11).SUBJECT!!!
	end	
	#dc11.subject??? not required for migration - see above
	
	
	#rights.
	#rights holder 0...1
	#checked data on dlib. all have the same rights statement and url cited, so this should work fine, as everything else is rights holders
	thesis_rightsholder = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[not(contains(.,'http')) and not (contains(.,'licenses')) ]",ns).each do |r|
	thesis_rightsholder.push(r)
	end
	puts "looked for rights holder"
	thesis_rightsholder.each do |r|
		thesis.rights_holder = r.to_s 
		puts "found rights holder " + thesis.rights_holder
	end	
	
	#license  set a default which will be overwritten if one is found. its the url, not the statement
	thesis_rights = defaultLicence
	thesis_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
	#thesis.license = thesis_rights.to_s
	thesis.rights = thesis_rights.to_s
	puts "found thesis rights "
	#rdf:type is boilerplate.dont need to add this 
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	thesis.depositor = "ps552@york.ac.uk"
	
	#save	
	thesis.save!	
	id = thesis.id
	puts "thesis id was " +id 
	#put in collection	
	col = Object::Collection.find(parentcol.to_s)# should this be CurationConcerns::Collection?
	
	#how about creating the collection programmatically instead? but then how do I add to it after the event? 
	puts "id of col was:" +col.id
	puts "got collection ok " + col.title[0].to_s
	col.members << thesis  
	col.save
	#TODO... create a fileset (MainFileSet) and add the content
	# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
		
	#try code below	
	#get a user
	users = Object::User.all #otherwise it will use one of the included modules
	user = users[0]	
	#populate new FileSet title field. give it permissions.
	mfset.title = ["main pdf content"]	
	mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	mfset.depositor = "ps552@york.ac.uk"
	
	#****make a child object to hold the generic file set and the content. generic work?
	childobject  = Dlibhydra::GenericWork.new  #NOT create!
	childobject.title = ["main thesis pdf"]
	childobject.preflabel = childobject.title[0]
	#dont add depositor or permissions, no methods in GenericWork for this
	
	#read content file
	#contentfile = open("/vagrant/files_to_test/testpdf.pdf")
	puts "just before creating content, pdf loc used is " + newpdfloc.to_s
	#contentfile = open(newpdfloc)
	contentfile = open("/vagrant/files_to_test/testpdf.pdf")
	
	puts "opened the content file" 
	
	#make filesetactor   CHOSS
#http://www.rubydoc.info/gems/curation_concerns/1.0.0/CurationConcerns/Actors/FileSetActor
	actor = CurationConcerns::Actors::FileSetActor.new(mfset, user)
	#essential metadata and content are created in this order	
	#actor.create_metadata(childobject)#that doesnt work	
	#actor.create_metadata(mfset) #nope, that doesnt work. needs to be the record object
	actor.create_metadata(thesis)#name of object its to be added to  
	puts "created metadata" 
	actor.create_content(contentfile, relation = 'original_file' )
	puts "created content"
   
	mfset.save!
	childobject.members << mfset
	childobject.save!
	thesis.members << childobject #could this be the critical bit?
	thesis.save!
	puts "done"
end


#bundle exec rake migrate_thesis[/vagrant/files_to_test/york_847953.xml,9s1616164]
# bundle exec rake migrate_thesis[/vagrant/files_to_test/york_21031.xml,9s1616164]
#def migrate_thesis(path,collection)
#bundle exec rake migrate_thesis[/vagrant/files_to_test/york_21031.xml,/vagrant/files_to_test/col_mapping.txt]
#emotional world etc
#bundle exec rake migrate_thesis[/vagrant/files_to_test/york_807119.xml,/vagrant/files_to_test/col_mapping.txt]   (the whole collects bundle needs recreation, col mapping txt includes empty year collections)
#bundle exec rake migrate_thesis[/vagrant/files_to_test/york_847953.xml,/vagrant/files_to_test/col_mapping.txt]
def migrate_thesis(path,collection_mapping_doc_path)
#mfset = Dlibhydra::FileSet.new   #FILESET. #defin this at top because otherwise expects to find it in CurationConcerns module 
mfset = Object::FileSet.new   #FILESET. #defin this at top because otherwise expects to find it in CurationConcerns module . 

puts "migrating a thesis"
	defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
	foxmlpath = path
	#parentcol = collection
	
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
	
	
	#this has local.fedora.host, which will be wrong. need to replace this 
	#reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	#needs to read (for development purposes on real machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	newpdfloc = pdf_loc.sub 'local.fedora.server', 'yodlapp3.york.ac.uk'
	localpdfloc = pdf_loc.sub 'http://local.fedora.server', '/vagrant/files_to_test'
	
	#dont continue to migrate file if content file not found
	if !File.exist?(localpdfloc)
		puts 'content file ' + localpdfloc.to_s + ' not found'	
		return
	else
		puts 'checked for ' + localpdfloc.to_s + ' found it present'
	end  
	
	
	#for initial development purposes on my machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	puts "edited pdf loc is :" + newpdfloc
	#create a new thesis implementing the dlibhydra models
	#thesis = CurationConcerns::Thesis.create
	thesis = Object::Thesis.create
	#start reading and populating  data
	titleArray =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	t = titleArray.to_s   #CHOSS - construct title!
	thesis.title = [t]	#1 only	
	thesis.preflabel =  thesis.title[0] # skos preferred lexical label (which in this case is same as the title. 1 0nly but can be at same time as title 
	##A thesis should only ever have one author (creator)	
	former_id = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:identifier/text()",ns).to_s
	if former_id.length > 0
	thesis.former_id = [former_id]
	end
	
	 creatorArray = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns).to_s
	 thesis.creator = [creatorArray.to_s]
	
	#abstract is currently the description. optional field so test presence
	thesis_abstract = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:description/text()",ns).to_s
	if thesis_abstract.length > 0
	thesis.abstract = thesis_abstract
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
		thesis.advisor.push(c)
	end	

   #departments and institutions (this gets wierd). need to do some data checking for splits etc. 
   #possible splits: York.  
   #without splits: Oxford Brookes University
   locations = []
	 doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:publisher/text()",ns).each  do |i|
	 locations.push(i.to_s)
	 end
	 locations.each do |loc|
		#first get the institution . 1 only. will overwrite if there
		#then add the department, splitting strings where required	
		if loc.include? "University of York"
			thesis.awarding_institution = "University of York"
			if loc.include? "York." 
				splitstring = loc.split('York.',2)#2nd param ensures it only splits into 2 parts
				thesis.department.push (splitstring[1])
			elsif loc.include? "York:"
				splitstring = loc.split('York:',2)
				thesis.department.push (splitstring[1])			
			end
	    elsif loc.include? "Institute of Advanced Architectural Studies"
			thesis.awarding_institution = "University of York"
			thesis.department.push ("Institute of Advanced Architectural Studies")
		elsif loc.include? "York Management School "
			thesis.awarding_institution = "University of York"
			thesis.department.push ("York Management School")        				
		elsif loc.include? "Oxford Brookes University"
			thesis.awarding_institution = "Oxford Brookes University"
		end
	end
	
	#work on this
	#qualification level, name, resource type
	# resource type should be added as a dc:subject 
	#ignore dcmi types
	typesToParse = []  #
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns).each do |t|	
	typesToParse.push(t)
	end
	#Arrays of qualification name variants
	artMasters = ['Master of Arts (MA)', 'Master of Arts', 'Master of Art (MA)', 'MA (Master of Arts)','Masters of Arts (MA)', 'MA']
	artBachelors = ['Batchelor of Arts (BA)', '"Bachelor of Arts (BA),"', 'BA', 'Bachelor of Arts (BA)']
	artsByResearch = ['Master of Arts by research (MRes)', '"Master of Arts, by research (MRes)"' ]
	scienceBachelors = ['Batchelor of science (BSc)', '"Bachelor of Science (BA),"', 'BSc', ]
	scienceMasters = ['Master of Science (MSc.)', '"Master of Science (MSc),"',"'Master of Science (MSc)",'Master of Science (MSc)','MSc', ]
	scienceByResearch  = ['Master of Science by research (MRes)']
	philosophyBachelors = ['Bachelor of Philosophy (BPhil)', 'BPhil']
	philosophyMasters = ['Master of Philosophy (MPhil)','MPhil']
	researchMasters = ['Master of Research (Mres)','Master of Research (MRes)','Mres','MRes']
	#the variant single quote character in  Conservation Studies is invalid and causes invalid multibyte char (UTF-8) eror so  handled this in nokogiri open document call. however we also need to ensure the resulting string is included in the lookup array so the match will still be found. this means recreating it and inserting it into the array
	not_valid = "Postgraduate Diploma in ‘Conservation Studies’ (PGDip)"
	valid_now = not_valid.encode('UTF-8', :invalid => :replace, :undef => :replace)
	conservationDiploma = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', valid_now]	
	medievalDiploma =['Postgraduate Diploma in Medieval Studies (PGDip)','PGDip']
	
	#degree levels - masters, batchelors, diploma
	masters = ['Masters','masters']
	bachelors = ['Bachelors','Bachelor','Batchelors', 'Batchelor']
	diplomas = ['Diploma','(Dip', '(Dip', 'Diploma (Dip)']
	
	#resource Types map to dc:subject. at present the only official value is Dissertations, Academic
	theses = [ 'theses','Theses','Dissertations','dissertations' ] 
	
	#now check which group (if any) is present and apply standard name
	typesToParse.each do |t|	
	type_to_test = t.to_s
	#check academic degree
	#this is now the vivo:AcademicDegree type in the model. it will be precisely one
		if artMasters.include? type_to_test
		 thesis.qualification_name = "Master of Arts (MA)"
		elsif artBachelors.include? type_to_test
		 thesis.qualification_name = "Bachelor of Arts (BA)"
		elsif artsByResearch.include? type_to_test
		 thesis.qualification_name = "Master of Arts by research (MRes)"
		elsif scienceBachelors.include? type_to_test
		 thesis.qualification_name = "Bachelor of Science (BSc)"
		elsif scienceMasters.include? type_to_test
		 thesis.qualification_name = "Master of Science (MSc)"
		elsif scienceByResearch.include? type_to_test
		 thesis.qualification_name = "Master of Science by research (MRes)"
	    elsif philosophyBachelors.include? type_to_test
		 thesis.qualification_name = "Bachelor of Philosophy (BPhil)"
		elsif philosophyMasters.include? type_to_test
		 thesis.qualification_name = "Master of Philosophy (MPhil)"
	    elsif researchMasters.include? type_to_test
		 thesis.qualification_name = "Master of Research (MRes)"
		elsif medievalDiploma.include? type_to_test
		 thesis.qualification_name = "Postgraduate Diploma in Medieval Studies (PGDip)"
		elsif conservationDiploma.include? type_to_test
		 thesis.qualification_name = "Postgraduate Diploma in Conservation Studies (PGDip)"
		end
		
	#now check for qualification levels. there can only be one
	if masters.include? type_to_test
		 thesis.qualification_level = "Masters"
	elsif bachelors.include? type_to_test
		 thesis.qualification_level = "Bachelors"
    elsif diplomas.include? type_to_test
		 thesis.qualification_level = "Postgraduate Diploma"
	end
	
	#now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
	if theses.include? type_to_test
		 thesis.subject.push("Dissertations, Academic")	
	end
end	
	
	
	thesis_language = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:language/text()",ns).each do |lan|
	thesis_language.push(lan.to_s)
	end
	thesis_language.each do |lan|   #0 ..n
		thesis.language.push(lan)
	end	
	
	#dc.keyword (formerly subject, as existing ones from migration are free text not lookup
	thesis_subject = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
	thesis_subject.push(s.to_s)
	end
	thesis_subject.each do |s|
	puts "found subject " +s.to_s
		thesis.keyword.push(s)   #TODO::THIS WAS ADDED TO FEDORA AS DC.RELATION NOT DC(OR DC11).SUBJECT!!!
	end	
	#dc11.subject??? not required for migration - see above
	
	
	#rights.
	#rights holder 0...1
	#checked data on dlib. all have the same rights statement and url cited, so this should work fine, as everything else is rights holders
=begin
	thesis_rightsholder = []	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[not(contains(.,'http')) and not (contains(.,'licenses')) ]",ns).each do |r|
	thesis_rightsholder.push(r)
	end
	puts "looked for rights holder"
	thesis_rightsholder.each do |r|
		thesis.rights_holder = r.to_s 
	end	
=end


   thesis_rightsholder = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[not(contains(.,'http')) and not (contains(.,'licenses')) ]",ns).to_s
   if thesis_rightsholder.length > 0
	thesis.rights_holder = thesis_rightholder   
   end

	#license  set a default which will be overwritten if one is found. its the url, not the statement
	#For full york list see https://dlib.york.ac.uk/yodl/app/home/licences. edit in rights.yml
	thesis_rights = defaultLicence
	thesis_rights = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:rights/text()[contains(.,'http')]",ns).to_s
	thesis.rights = [thesis_rights.to_s] # multivalued in Object::Thesis def
	
	#rdf:type is boilerplate.dont need to add this 
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	thesis.depositor = "ps552@york.ac.uk"
	
	#save	
	thesis.save!	
	id = thesis.id
	puts "thesis id was " +id 
	#put in collection	
	col = Object::Collection.find(parentcol.to_s)	
	puts "id of col was:" +col.id
	puts "got collection ok " + col.title[0].to_s
	col.members << thesis  
	col.save
	#TODO... create a fileset (MainFileSet) and add the content
	# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
		
	#try code below	
	#get a user
	users = Object::User.all #otherwise it will use one of the included modules
	user = users[0]	
	#populate new FileSet title field. give it permissions.
	mfset.title = ["THESIS_MAIN"]	#needs to be same label as content file in foxml 
	mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	mfset.depositor = "ps552@york.ac.uk"
		
	#read content file
	#contentfile = open("/vagrant/files_to_test/testpdf.pdf")
	puts "just before creating content, pdf loc used is " + localpdfloc.to_s
	#contentfile = open(newpdfloc) #at present content has to sit on same server. could in real application probably get by sftp
	contentfile = open(localpdfloc) #ie '/vagrant/files_to_test/filename'
	
	puts "opened the content file" 
	
	#make filesetactor  
#http://www.rubydoc.info/gems/curation_concerns/1.0.0/CurationConcerns/Actors/FileSetActor
	actor = CurationConcerns::Actors::FileSetActor.new(mfset, user)
	#essential metadata and content are created in this order	
	actor.create_metadata(thesis)#name of object its to be added to  
	puts "created metadata" 
	actor.create_content(contentfile, relation = 'original_file' )
	puts "created content"
   
	mfset.save!

   thesis.mainfile << mfset	   #assume this also sets mainfile_ids[]
end






end #end of class