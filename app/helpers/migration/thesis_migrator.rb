# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# methods to create the  collection structure and do migrations
class ThesisMigrator
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra

#check its at least valid ruby
def test
puts "yup, foxml_reader still working"
end

#for the moment the parameter col_id_or_dummy is there to input the parent collection id (NOT the former pid) if using a flat collection structure. otherwise input the string DUMMY (the exact term doesnt matter, but this will do) in order to not break the method signature
# dev server CLEAN rake migration_tasks:bulk_migrate_theses[/home/dlib/peri_clean/testfiles/foxml/thesis_records/all,/home/dlib/peri_clean/testfiles/foxdone/theses/all,https://dlib.york.ac.uk,ps552@york.ac.uk]]
def bulk_migrate_theses_with_content_url(path_to_fox, path_to_foxdone, content_server_url, user)
puts "doing a bulk migration"
fname = "/opt/york/digilib/peri_ingest_clean/tmp/tally.txt"
tallyfile = File.open(fname, "a")
Dir.foreach(path_to_fox)do |item|
    	
	# we dont want to try and act on the current and parent directories
	next if item == '.' or item == '..'
	itempath = path_to_fox + "/" + item
	result = 9  # so this wont do the actions required if it isnt reset
	begin
		result = migrate_thesis_with_content_url(itempath,content_server_url,user)
	rescue
		result = 1	
		tallyfile.puts("rescue says FAILED TO INGEST "+ itempath)  
	end
	if result == 0
		tallyfile.puts("ingested " + itempath)
		FileUtils.mv(itempath, path_to_foxdone + "/" + item)  # move files once migrated
	elsif result == 1   # this may well not work, as it may stop part way through before it ever gets here. rescue block might help?
		tallyfile.puts("FAILED TO INGEST "+ itempath)
	elsif result == 2   # apparently some records may not have an actual resource paper of any id!
		tallyfile.puts("ingested metadata but NO EXAM_PAPER IN "+ itempath)		
		FileUtils.mv(itempath, path_to_foxdone + "/" + item)  # move files once migrated
	elsif result == 3   # couldnt identify parent collection in mappings
		tallyfile.puts("FAILED TO INGEST " + itempath + " because couldnt identiy parent collection mapping")
	elsif result == 4   # this may well not work, as it may stop part way through before it ever gets here. 
		tallyfile.puts("FAILED TO INGEST RESOURCE DOCUMENT IN"+ itempath)
	else
        tallyfile.puts(" didnt return expected value of 0 or 1 ")	
	end
	
end

tallyfile.close
puts "all done"
end  # end bulk_migrate_theses_with_content_url





	

def migrate_thesis_with_content_url(path, content_server_url, user) 
#create a uniquely named tracking file to provide metrics

#a simple id list to enable easy bulk deletion
id_list_filename = "/opt/york/digilib/peri_ingest_clean/tmp/new_theses_ids.txt"
id_list_file = File.open(id_list_filename, "a")

#a mapping file to support crossmatching
pid_to_id_filename = "/opt/york/digilib/peri_ingest_clean/tmp/thesis_pid_to_id_mappings.txt"
record_mapping_file = File.open(pid_to_id_filename, "a")

#metrics file for debugging and dev
filename = path.match(/york_\S+/) #will give  just the actual filename
filename = filename.to_s
tname = "/opt/york/digilib/peri_ingest_clean/tmp/thesis_metrics_" + filename + ".txt"
metricsfile = File.open(tname, "a")
metricsfile.puts( "am now working on " + filename + "  "  + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
metricsfile = File.open(tname, "a")
metricsfile.puts( "am now working on " + filename + "  "  + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))

result = 1 # default is fail

mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . (app one is not namespaced)
	metricsfile.puts( "created the initial empty pdf fileset" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
common = CommonMigrationMethods.new
puts "migrating a thesis with content url"	
	foxmlpath = path	
	# enforce  UTF-8 compliance when opening foxml file
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
	# doesnt resolve nested namespaces, this fixes that
    ns = doc.collect_namespaces		
	
	# find max dc version
	nums = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/@ID",ns)	
	all = nums.to_s
	current = all.rpartition('.').last 
	currentVersion = 'DC.' + current
	
	# find the max THESIS_MAIN version
	thesis_nums = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion/@ID",ns)	
	#check the state is active
	idstate = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/@STATE",ns)
	#note resource state isnt active, but dont stop processing
	if !idstate.to_s=="A"
		#ingest_note = " no active THESIS"
		result = 2
		#return result  #in some cases there may be no active resource paper
	end	
	thesis_all = thesis_nums.to_s
	thesis_current = thesis_all.rpartition('.').last 
	currentThesisVersion = 'THESIS_MAIN.' + thesis_current
	# GET CONTENT - get the location of the pdf as a string
	pdf_loc = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion[@ID='#{currentThesisVersion}']/foxml:contentLocation/@REF",ns).to_s	
	#if THESIS_MAIN location isnt found, stop processing and return error result code
	if pdf_loc.length <= 0
		result = 2 
		#process anyway
	end	
	
	# CONTENT FILES
	# this has local.fedora.host, which will be wrong. need to replace this with whereever they will be sitting 
	# reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	# needs to read (for development purposes on real machine) http://yodlapp3.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf	
	
	if pdf_loc.length > 0
		externalpdfurl = pdf_loc.sub 'http://local.fedora.server', content_server_url #this will be added to below. once we have external urls can add in relevant url
		externalpdflabel = "THESIS_MAIN"  #default
		# label needed for gui display
			label = doc.xpath("//foxml:datastream[@ID='THESIS_MAIN']/foxml:datastreamVersion[@ID='#{currentThesisVersion}']/@LABEL",ns).to_s 
			if label.length > 0
			externalpdflabel = label #in all cases I can think of this will be the same as the default, but just to be sure
			end
	end
	# hash for any THESIS_ADDITIONAL URLs. needs to be done here rather than later to ensure we obtain overridden version og FileSet class rather than CC as local version not namespaced
	metricsfile.puts( "about to create additional filesets for THESIS_ADDITIONAL" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	additional_filesets = {}	
	elems = doc.xpath("//foxml:datastream[@ID]",ns)
	elems.each { |id| 
		idname = id.attr('ID')		
		if idname.start_with?('THESIS_ADDITIONAL')
			#check its active
			idstate = id.attr('STATE')
			if idstate == "A"
				#ok, now need to find the latest version 
				version_nums = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion/@ID",ns)
				current_version_num = version_nums.to_s.rpartition('.').last
				current_version_name = idname + '.' + current_version_num
				addit_file_loc = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/foxml:contentLocation/@REF",ns).to_s
				addit_file_loc = addit_file_loc.sub 'http://local.fedora.server', content_server_url
				fileset = Object::FileSet.new
				#fileset.filetype = 'externalurl'
				fileset.filetype = 'managed'   #ie a file streamed from apache
				fileset.external_file_url = addit_file_loc
				fileset.title = [idname]
				# may have a label - needed for display-  that is different to the datastream title
				label = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/@LABEL",ns).to_s 
				if label.length > 0
					fileset.label = label
				end
				fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
				fileset.depositor = user
				additional_filesets[idname] = fileset
			end
		end
	}
	metricsfile.puts( "finished creating additional filesets for THESIS_ADDITIONAL" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	metricsfile.puts( "about to create additional filesets for ORIGINAL_RESOURCE" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	#also look for ORIGINAL_RESOURCE
	elems = doc.xpath("//foxml:datastream[@ID]",ns)
	elems.each { |id| 
		idname = id.attr('ID')		
		if idname.start_with?('ORIGINAL_RESOURCE')
		#check its active
		idstate = id.attr('STATE')
		if idstate == "A"		
	#ok, now need to find the latest version 
				version_nums = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion/@ID",ns)
				current_version_num = version_nums.to_s.rpartition('.').last
				current_version_name = idname + '.' + current_version_num
				addit_file_loc = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/foxml:contentLocation/@REF",ns).to_s
				addit_file_loc = addit_file_loc.sub 'http://local.fedora.server', content_server_url
				fileset = Object::FileSet.new
				#fileset.filetype = 'externalurl'
				fileset.filetype = 'managed'
				fileset.external_file_url = addit_file_loc
				fileset.title = [idname]
				# may have a label - needed for display-  that is different to the datastream title
				label = doc.xpath("//foxml:datastream[@ID='#{idname}']/foxml:datastreamVersion[@ID='#{current_version_name}']/@LABEL",ns).to_s 
				if label.length > 0
					fileset.label = label
				end
				fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", 	:access => "edit"})]
				fileset.depositor = user
				additional_filesets[idname] = fileset
			end
		end
	}
	metricsfile.puts( "finished creating additional filesets for THESIS_ADDITIONAL" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))	
	# create a new thesis implementing the dlibhydra models
	metricsfile.puts( "about to create and populate the thesis itself" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	thesis = Object::Thesis.new

	# once depositor and permissions defined, object can be saved at any time
	thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
	thesis.depositor = user
	
	# start reading and populating  data
	title =  doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns).to_s
	title = title.to_s
	title.gsub!("&amp;","&")
		
	thesis.title = [title]	# 1 only	
	# thesis.preflabel =  thesis.title[0] # skos preferred lexical label (which in this case is same as the title. 1 0nly but can be at same time as title 
	#EEK! not all the records have dc:identifier populated
	#former_id = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:identifier/text()",ns).to_s
	former_id = doc.xpath("//foxml:digitalObject/@PID",ns).to_s
	if former_id.length > 0
	thesis.former_id = [former_id]
	end
	
	# could really do with a file to list what its starting work on as a cleanup tool. doesnt matter if it doesnt get this far as there wont be anything to clean up
	#this is the main tracking text which lists what is done. keep this separate as the idea is it still writes even if things fail at a later stage
	tname = "/opt/york/digilib/peri_ingest_clean/tmp/tracking.txt"
	trackingfile = File.open(tname, "a")
	trackingfile.puts( "am now working on " + former_id + " title:" + title )
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
   metricsfile.puts( "about to create start matching authority elements (departments and institutions)" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
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
	metricsfile.puts( "done with authority elements (departments and institutions)" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	metricsfile.puts( "about to create start matching authority elements (qualification levels, names , resource types and institutions)" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
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
	qual_levels = []
	levels = common.get_qualification_level_term(type_to_test)
	levels.each do |level|		
		if !qual_levels.include? level #avoid duplication
			qual_levels.push(level)
		end	
	end
	qual_levels.each do |ql|
		thesis.qualification_level += [ql]
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
    metricsfile.puts( "done with authority elements (qualification names, level, resource types)" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	thesis_language = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:language/text()",ns).each do |lan|
	thesis_language.push(lan.to_s)
	end
	metricsfile.puts( "getting authority elements (language)" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	# this should return the key as that allows us to just search on the term
	thesis_language.each do |lan|   #0 ..n
	standard_language = "unfound"
	    standard_language = common.get_standard_language(lan.titleize)#capitalise first letter
		if standard_language!= "unfound"
			thesis.language+=[standard_language]
		end
	end	
	metricsfile.puts( "done getting language" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	# dc.keyword (formerly subject, as existing ones from migration are free text not lookup
	thesis_subject = []
	doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns).each do |s|
	thesis_subject.push(s.to_s)
	end
	thesis_subject.each do |s|
	    s = s.to_s
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
	
	metricsfile.puts( "getting the user" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	users = Object::User.all #otherwise it will use one of the included modules
	user_object = users[0]
	metricsfile.puts( "got the user" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	#check we do have a main resource paper before trying to add it
	metricsfile.puts( "now adding the thesis mainfile metadata" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	if pdf_loc.length >0
		begin
			# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
			mfset.filetype = 'managed'
			mfset.title = ["THESIS_MAIN"]	#needs to be same label as content file in foxml 
			mfset.label = externalpdflabel
			# add the external content URL
			mfset.external_file_url = externalpdfurl
			actor = CurationConcerns::Actors::FileSetActor.new(mfset, user_object)
			actor.create_metadata(thesis)
			#Declare file as external resource
			Hydra::Works::AddExternalFileToFileSet.call(mfset, externalpdfurl, 'external_url')
			mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			mfset.depositor = user
			mfset.save!
			puts "fileset " + mfset.id + " saved"
    				
			thesis.mainfile << mfset
			metricsfile.puts( "ADDED the thesis mainfile metadata" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))			
			#metricsfile.puts( "saving thesis" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
			#thesis.save!
			#metricsfile.puts( "thesis saved" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
		rescue
			puts "QUACK QUACK OOPS! addition of external file unsuccesful"
			result = 4
			return result		
		end   
     puts "all done for external content mainfile " + mfset.id  
	end
metricsfile.puts( "saving thesis" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))	
thesis.save!
metricsfile.puts( "thesis saved" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
puts (" new id of thesis " + thesis.id.to_s)
# process external THESIS_ADDITIONAL files
metricsfile.puts( "adding additional filesets metadata" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
for key in additional_filesets.keys() do		
		additional_thesis_file_fs = additional_filesets[key]		
		#add metadata to make fileset appear as a child of the object
        actor = CurationConcerns::Actors::FileSetActor.new(additional_thesis_file_fs, user_object)
        actor.create_metadata(thesis)
		#Declare file as external resource
		url = additional_thesis_file_fs.external_file_url
        Hydra::Works::AddExternalFileToFileSet.call(additional_thesis_file_fs, url, 'external_url')
        additional_thesis_file_fs.save!
		thesis.members << additional_thesis_file_fs
        thesis.save!
		puts "all done for  additional file " + key
end
metricsfile.puts( "added any additional filesets metadata" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	#when done, explicity reset big things to empty to ensure resources not hung on to
	additional_filesets = {} 
    doc = nil
	mapping_text = nil
	collection_mappings = {}
metricsfile.puts( "ALL DONE!" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))	
	if result != 2
		result = 0 #this needs to happen last
	end 
   id_list_file.puts(thesis.id)	
   id_list_file.close   
   record_mapping_file.puts(thesis.former_id[0].to_s + "," + thesis.id)
   record_mapping_file.close
   return result   # must be last!
end # end of migrate_thesis_with_content_url

end # end of class
