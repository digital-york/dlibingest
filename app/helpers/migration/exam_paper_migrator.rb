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


def say_hello
	puts "HODOR!"
end

# rake migration_tasks:bulk_migrate_exams[/home/dlib/exams_src_and_output_files/foxml,/home/dlib/exams_src_and_output_files/foxdone,https://dlib.york.ac.uk, /home/dlib/exams_src_and_output_files,user]
def batch_migrate_exams(path_to_fox, path_to_foxdone, content_server_url, outputs_dir, user)
puts "doing a bulk migration of exams"
fname = outputs_dir + "/exam_tally.txt"
tallyfile = File.open(fname, "a")
	
Dir.foreach(path_to_fox)do |item|	
	# we dont want to try and act on the current and parent directories
	next if item == '.' or item == '..'
	
	itempath = path_to_fox + "/" + item
	result = 9  # so this wont do the actions required if it isnt reset
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
		#sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
	elsif result == 2   # apparently some records may not have an actual exam paper of any id!
		tallyfile.puts("ingested metadata but NO EXAM_PAPER IN "+ itempath)
		#sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
		FileUtils.mv(itempath, path_to_foxdone + "/" + item)  # move files once migrated	
	elsif result == 4   # this may well not work, as it may stop part way through before it ever gets here. 
		tallyfile.puts("FAILED TO INGEST RESOURCE DOCUMENT IN"+ itempath)
		#sleep 10 # wait 10 seconds to try to resolve 'exception rentered (fatal)' (possible threading?) problems
	else
        tallyfile.puts(" didnt return expected value of 0 or 1 or 2")	
	end
end
tallyfile.close
puts "all done"
end # end batch_migrate_exams



# adds the content file url, not embedded content 
# rake migration_tasks:migrate_exam_paper[/home/dlib/exams_src_and_output_files/foxml/york_xxxx.xml,https://dlib.york.ac.uk,/home/dlib/exams_src_and_output_files,ps552@york.ac.uk]
def migrate_exam(path, content_server_url, outputs_dir, user)
    #metrics file for debugging and dev
	filename = path.match(/york_\S+/) #will give  just the actual filename
	filename = filename.to_s
	tname = outputs_dir+"/exam_metrics.txt"
	metricsfile = File.open(tname, "a")
	metricsfile.puts(  filename + ","  + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	

 
	result = 1 # default is fail
	mfset = Object::FileSet.new   # FILESET. # define this at top because otherwise expects to find it in CurationConcerns module . (app one is not namespaced)
	common = CommonMigrationMethods.new
	puts "migrating  exam with content url"	
	foxmlpath = path.to_s		
	# enforce  UTF-8 compliance when opening foxml file
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
	# doesnt resolve nested namespaces, this fixes that
    ns = doc.collect_namespaces	
	
	# find max dc version
	nums = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/@ID",ns)	
	all = nums.to_s
	current = all.rpartition('.').last 
	currentVersion = 'DC.' + current
	
	# find the max EXAM_PAPER version. no variants on this
	exam_paper_nums = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/foxml:datastreamVersion/@ID",ns)	
	idstate = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/@STATE",ns)  
	#note EXAM_PAPER state isnt active, but dont stop processing
	#ingest_note = ""
	if !(idstate.to_s == "A")	
		#ingest_note = " no active EXAM_PAPER"
		result = 2
		#return result  #in some cases there may be no active exam paper
	end	
	
	exam_paper_all = exam_paper_nums.to_s
	exam_paper_current = exam_paper_all.rpartition('.').last 
	currentExamPaperVersion = 'EXAM_PAPER.' + exam_paper_current
	# GET CONTENT - get the location of the pdf as a string
	pdf_loc = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/foxml:datastreamVersion[@ID='#{currentExamPaperVersion}']/foxml:contentLocation/@REF",ns).to_s	
	#if EXAM_PAPERlocation isnt found, set result code accordingly
	if pdf_loc.length <= 0        
		result = 2 
	#return result  #in this case we should process anyway
	end	
	#this is because exam papers may exist in several locations
	#establish permissions from ACL datastream before setting in object. set a variable accordingly for easy reference 
	#throughout class
	# find max ACL version
	acl_nums = doc.xpath("//foxml:datastream[@ID='ACL']/foxml:datastreamVersion/@ID",ns)	
	acl_all = nums.to_s
	acl_current = all.rpartition('.').last 
	acl_currentVersion = 'ACL.' + current
	#get access value for user 'york'
	yorkaccess = doc.xpath("//foxml:datastream[@ID='ACL']/foxml:datastreamVersion[@ID='#{acl_currentVersion}']/foxml:xmlContent/acl:container/acl:role[@name='york']/text()",ns).to_s#get access value for user 'york'   
	
	# CONTENT FILES
	# this has local.fedora.host, which will be wrong. need to replace this with whereever they will be sitting 
	# reads http://local.fedora.server/digilibImages/HOA/current/X/20150204/xforms_upload_whatever.tmp.pdf
	# needs to read (for development purposes on real machine) http://dlib.york.ac.uk/digilibImages/HOA/current/X/20150204/xforms_upload_4whatever.tmp.pdf
	#and the content_server_url is set in the parameters :-)
	if pdf_loc.length > 0
		externalpdfurl = pdf_loc.sub 'http://local.fedora.server', content_server_url 
		externalpdflabel = "EXAM_PAPER"  #default
		# label needed for gui display
		label = doc.xpath("//foxml:datastream[@ID='EXAM_PAPER']/foxml:datastreamVersion[@ID='#{currentExamPaperVersion}']/@LABEL",ns).to_s 
		if label.length > 0
			externalpdflabel = label #in all cases I can think of this will be the same as the default, but just to be sure
		end
		#these wont have the same name.need to search for them. utilty scripts available
		# hash for any additional files that may emerge. may not be any. needs to be done here rather than later to ensure we obtain overridden version of FileSet class rather than CC as local version not namespaced
	end
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
			#fileset.filetype = 'externalurl'
			fileset.filetype = 'managed' #ie streamed from apache
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
	
	# once depositor and permissions defined, object can be saved at any time
	#there will be different permissions according to whether these are from the restricted exams
	#or the general york availability exams. This is determined from the ACL datastream.
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
	
	#additional step for CEFR exams and foundation exams, add full name listing to descriptions
	typesToParse.each do |t|
	t = t.to_s
	td = t.downcase
		if td.include? "cefr"
			exam.description += [td]
		elsif td.include? "foundation"
			exam.description += [td] 
		end
	end
	# qualification levels (yml file). 
	typesToParse.each do |t|	 
	type_to_test = t.to_s
	#qual_levels = common.get_qualification_level_term(type_to_test) 
	qual_levels = []
	levels = common.get_qualification_level_term(type_to_test)#returned as an array although in most cases there is just 1 or 0
	levels.each do |level|
		if !qual_levels.include? level #avoid duplication
			qual_levels.push(level)
		end	
	end
	
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
	
	
	users = Object::User.all #otherwise it will use one of the included modules
	#this only works when we always know who user[0] is, so rewrite
	#user_object = users[0]	
	for user_obj in users do
		email = user_obj.email
		if email == user
			user_object = user_obj
		else
			user_object = users[0]
		end
	end
	
	#check we do have a main EXAM_PAPER before trying to add it
	if pdf_loc.length > 0
		begin
			# see https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb#L54 and https://github.com/pulibrary/plum/blob/master/lib/tasks/ingest_mets.rake#L3-L4
			#mfset.filetype = 'externalurl'
			mfset.filetype = 'managed' #ie streamed from apache
			mfset.title = ["EXAM_PAPER"]	#needs to be same label as content file in foxml 
			mfset.label = externalpdflabel
			# add the external content URL
			mfset.external_file_url = externalpdfurl
			actor = CurationConcerns::Actors::FileSetActor.new(mfset, user_object)
			actor.create_metadata(exam)
			#Declare file as external resourcexternalFileToFileSet adds url of external file to fileset metadata "+ " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
			#NOTE TO SELF should the url now rerad "managed" since the name has changed?
			#this affects the fromt end so at present does not need changing to 'managed' to match the fileset urltype
			Hydra::Works::AddExternalFileToFileSet.call(mfset, externalpdfurl, 'external_url')
			if yorkaccess == 'DENY'
				mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "admin", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			else
				mfset.permissions = [Hydra::AccessControls::Permission.new({:name=> "york", :type=>"group", :access=>"read"}), Hydra::AccessControls::Permission.new({:name=>"admin", :type=> "group", :access => "edit"})]
			end 			
			
			mfset.depositor = user
			mfset.save!
			puts "fileset " + mfset.id + " saved" 
			exam.mainfile << mfset
			puts "mainfile ids in exam :" + exam.mainfile_ids[0].to_s			
		rescue
			puts "QUACK QUACK OOPS! addition of external file unsuccesful"
			result = 4
			return result		
		end   
		puts "all done for external content mainfile " + mfset.id
        		
	end  

# process external EXAM_ADDITIONAL files (not edited for exams, just keeping for reference)
for key in additional_filesets.keys() do		
		additional_exam_file_fs = additional_filesets[key]		
		#add metadata to make fileset appear as a child of the object
        actor = CurationConcerns::Actors::FileSetActor.new(additional_exam_file_fs, user_object)
        actor.create_metadata(exam)
		#Declare file as external resource
		url = additional_exam_file_fs.external_file_url
        Hydra::Works::AddExternalFileToFileSet.call(additional_exam_file_fs, url, 'external_url')
        additional_exam_file_fs.save!
		exam.members << additional_exam_file_fs
		
		puts "all done for  additional file " + key
end
	exam.depositor = user
	exam.save!
	exam_id = exam.id
	metricsfile.puts(exam_id+ ", " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))	
	#when done, explicity reset big things to empty to ensure resources not hung on to
	additional_filesets = {} 
    doc = nil
	mapping_text = nil
	collection_mappings = {}	
	if result != 2
		result = 0 
	end
	#make this output the metrics info
	#trackingfile.puts( "finished" + " " + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
	metricsfile.close
	puts "finished"
   return result   # make sure this happens last
end # end of migrate_exam_paper

end # end of class
