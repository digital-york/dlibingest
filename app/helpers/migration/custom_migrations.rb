# encoding: UTF-8
require 'nokogiri'
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







#version of migration that adds the content file url but does not ingest the content pdf into the thesis
# on megastack: # rake migration_tasks:migrate_thesis_with_content_url[id,https://dlib.york.ac.uk]
# on dlibdev0: # rake migration_tasks:migrate_thesis_with_content_url[id,https://dlib.york.ac.uk]
#def migrate_bhutan_thesis_with_content_url(path, content_server_url, collection_mapping_doc_path) 
#dont need the thesis pid because this is a one-off for a very odd and anomalous record
def migrate_bhutan_thesis_with_content_urls(collection_id, content_server_url, user) 

mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . (app one is not namespaced)
puts "migrating the bhutan thesis"	
common = CommonMigrationMethods.new
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
			fileset1.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			fileset1.depositor = user
			additional_filesets["ORIGINAL_RESOURCE1"] = fileset1	
			
			#audio file Appendix 2
			fileset2 = Object::FileSet.new
			fileset2.filetype = 'externalurl'
			fileset2.external_file_url = content_server_url + "/digilibImages/music/musicPreserved/X/20170308/xforms_upload_4867028519326396466.tmp"
			fileset2.title = ["ORIGINAL_RESOURCE"]
			# should this be the original title of the content file in this case? 			
			fileset2.label = "Appendix 2:Interview with the villagers (audio, m4a)"
			fileset2.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			fileset2.depositor = user
			additional_filesets["ORIGINAL_RESOURCE2"] = fileset2	
	puts "total of " + additional_filesets.size.to_s + "additional filesets created"
	# create a new thesis implementing the dlibhydra models
	thesis = Object::Thesis.new
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	thesis.depositor = user
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
	id = common.get_resource_id('institution', inst_preflabel)
	thesis.awarding_institution_resource_ids+=[id]
	id = common.get_resource_id('department',  "University of York. Department of Archaeology")
	thesis.department_resource_ids +=[id]
	
	
	#qualification fields
	typesToParse = []  #
	typesToParse.push("Master of Arts (MA)")	
	qualification_name_preflabel = get_qualification_name_preflabel(typesToParse)	
	qname_id = common.get_resource_id('qualification_name',qualification_name_preflabel)
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
		subject_id = common.get_resource_id('subject',"Dissertations, Academic")
		thesis.subject_resource_ids +=[subject_id]		 
	#end

	#language wasnt specified in foxml object, but clearly is (checked)
	standard_language = "unfound"
	# this should return the key as that allows us to just search on the term	
	standard_language = common.get_standard_language("English")#capitalise first letter
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
		mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
		mfset.depositor = user
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
