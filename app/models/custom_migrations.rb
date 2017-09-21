# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# methods to perform custom migrations for anomalous records
#its assumed that collection structures will already be in place, and the appropraite collection in the samvera install
#will be passed in as a param
class CustomMigrations
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra



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
if searchterm.include?("yorkrestricted")
  term = 'York Restricted'
end
	auth = Qa::Authorities::Local::FileBasedAuthority.new('licenses') 
	rights = auth.search(term)[0]['id']
end





#version of migration that adds the content file url but does not ingest the content pdf into the thesis
# on megastack: # rake migration_tasks:migrate_thesis_with_content_url[id,https://dlib.york.ac.uk]
# on dlibdev0: # rake migration_tasks:migrate_thesis_with_content_url[id,https://dlib.york.ac.uk]
#def migrate_bhutan_thesis_with_content_url(path, content_server_url, collection_mapping_doc_path) 
#dont need the thesis pid because this is a one-off for a very odd and anomalous record
def migrate_bhutan_thesis_with_content_urls(collection_id,content_server_url) 

mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . (app one is not namespaced)
puts "migrating the bhutan thesis"	

	parentcol = collection_id	
	# CONTENT FILES
	# this has local.fedora.host, which will be wrong. need to replace this with whereever they will be sitting 
	# reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	# needs to read (for development purposes on real machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	# newpdfloc = pdf_loc.sub 'local.fedora.server', 'yodlapp3.york.ac.uk'  # CHOSS we dont need this any more as we cant download remotely
	#and the content_server_url is set in the parameters :-)
	externalpdfurl =  content_server_url + "/digilibImages/HOA/current/X/20170308/xforms_upload_2922242419159768615.tmp.pdf"
    externalpdflabel = "THESIS_MAIN"  #default		
	# hash for  original resource content files. needs to be done here rather than later to ensure we obtain overridden version og FileSet class rather than CC as local version not namespaced
    additional_filesets = {}
			#audio file Appendix 1			
			fileset1 = Object::FileSet.new
			fileset1.filetype = 'externalurl'
			#note the two records in the original have been mistakenly both given the title Appendix 2
			fileset1.external_file_url = content_server_url + "/digilibImages/music/musicPreserved/X/20170308/xforms_upload_1357424874944822208.tmp"
			fileset1.title = ["ORIGINAL_RESOURCE"]
			# should this be the original title of the content file in this case? 			
			#both were given name of Appendix 2 in the foxml record, listened and compared to work out which was which. amcertain I have allocated the titles correctly, Appendix numbers not in original 
			fileset1.label = "Appendix 1: Interview of the Gup (Head of Talo Block) (audio, m4a)"
			fileset1.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
			fileset1.depositor = "ps552@york.ac.uk"
			additional_filesets["ORIGINAL_RESOURCE1"] = fileset1	
			
			#audio file Appendix 2
			fileset2 = Object::FileSet.new
			fileset2.filetype = 'externalurl'
			fileset2.external_file_url = content_server_url + "/digilibImages/music/musicPreserved/X/20170308/xforms_upload_4867028519326396466.tmp"
			fileset2.title = ["ORIGINAL_RESOURCE"]
			# should this be the original title of the content file in this case? 			
			fileset2.label = "Appendix 2:Interview with the villagers (audio, m4a)"
			fileset2.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
			fileset2.depositor = "ps552@york.ac.uk"
			additional_filesets["ORIGINAL_RESOURCE2"] = fileset2	
	puts "total of " + additional_filesets.size.to_s + "additional filesets created"
	# create a new thesis implementing the dlibhydra models
	thesis = Object::Thesis.new
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"ps552@york.ac.uk", :type=> "person", :access => "edit"})]
	thesis.depositor = "ps552@york.ac.uk"
	# start populating  data	
	thesis.title = ["Heritage of the community, and for the community: a case study from Bhutan"]	# 1 only	
	# thesis.preflabel =  thesis.title[0] # skos preferred lexical label (which in this case is same as the title. 1 0nly but can be at same time as title 
	#multiple objects so in this case list them all
	thesis.former_id.push("york:931160")
	thesis.former_id.push("york:931918")
	thesis.former_id.push("york:931921")
	thesis.former_id.push("york:931922")
	thesis.former_id.push("york:931923")
	
	thesis.creator_string = ["Pema"]
	# no abstract in foxml, just a  description. However when I opened the original pdf I found this WAS in fact the abstrat, so have entered as such
	thesis.abstract = ["The research examines the emergence and development of the idea of community engagement in the process of conservation and management of heritage. The research explores and analyzes ways and means, to involve and allow community participation in conserving and sustaining the significance of heritage in a particular context with reference to a case study from Bhutan. The research also explores the interpretation of the concept of cultural landscape in Bhutan, and importance of ensuring continuity of the community for conserving and sustaining the significance of cultural landscape of Bhutan."] # now multivalued
	# date_of_award (dateAccepted in the dc created by the model) 1 only
	thesis.date_of_award = "2016"	
	thesis.advisor_string.push("Chitty, Gill")
	 # departments and institutions 
	inst_preflabel = "University of York"
	id = get_resource_id('institution', inst_preflabel)
	thesis.awarding_institution_resource_ids+=[id]
	id = get_resource_id('department',  "University of York. Department of Archaeology")
	thesis.department_resource_ids +=[id]
	
	
	#qualification fields
	typesToParse = []  #
	typesToParse.push("Master of Arts (MA)")	
	qualification_name_preflabel = get_qualification_name_preflabel(typesToParse)	
	qname_id = get_resource_id('qualification_name',qualification_name_preflabel)
	if qname_id.to_s != "unfound"		
		thesis.qualification_name_resource_ids+=[qname_id]
	else
		puts "no qualification nameid found"
	end
	
	thesis.qualification_level += ["Masters (Postgraduate)"]
	

	# now check for certain award types, and if found map to subjects (dc:subject not dc:11 subject)
	# resource Types map to dc:subject. at present the only official value is Dissertations, Academic
	#theses = [ 'theses','Theses','Dissertations','dissertations' ] 
	#if theses.include? type_to_test	
	# not using methods below yet - or are we? subjects[] no longer in model
		subject_id = get_resource_id('subject',"Dissertations, Academic")
		thesis.subject_resource_ids +=[subject_id]		 
	#end

	#language wasnt specified in foxml object, but clearly is (checked)
	standard_language = "unfound"
	# this should return the key as that allows us to just search on the term	
	standard_language = get_standard_language("English")#capitalise first letter
	if standard_language!= "unfound"
		thesis.language+=[standard_language]
	end
	
	# dc.keyword (formerly subject, as existing ones from migration are free text not lookup. no subjects in foxml so no action
	# rights.	
	# rights holder 0...1
	# checked data on dlib. all have the same rights statement and url cited, so this should work fine, as everything else is rights holders
	thesis.rights_holder=["Pema"]
	# license  set a default which will be overwritten if one is found. its the url, not the statement. use licenses.yml not rights_statement.yml
	# For full york list see https://dlib.york.ac.uk/yodl/app/home/licences. edit in rights.yml
	defaultLicence = "http://dlib.york.ac.uk/licences#yorkrestricted"
	thesis_rights = defaultLicence
	thesis_rights = defaultLicence
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
	col = Object::Collection.find(collection_id)	
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
	end   
     puts "all done for external content mainfile " + id  

# process external THESIS_ADDITIONAL files
for key in additional_filesets.keys() do		

		additional_thesis_fileset = additional_filesets[key]		
		puts "found additional fileset " + additional_thesis_fileset.label
		#add metadata to make fileset appear as a child of the object
        actor = CurationConcerns::Actors::FileSetActor.new(additional_thesis_fileset, user)
        actor.create_metadata(thesis)
		#Declare file as external resource
		url = additional_thesis_fileset.external_file_url
        Hydra::Works::AddExternalFileToFileSet.call(additional_thesis_fileset, url, 'external_url')
        additional_thesis_fileset.save!
		thesis.members << additional_thesis_fileset
        thesis.save!
		puts "all done for  additional file " + key
end
	#when done, explicity reset big things to empty to ensure resources not hung on to
	additional_filesets = {} 
    doc = nil
	mapping_text = nil
	collection_mappings = {}	

   
end # end of migrate_thesis_with_content_url

end # end of class
