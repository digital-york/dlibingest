# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# methods to create the  collection structure and do migrations
class CommonMigrationMethods
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra

def say_hi
puts "hi"
end


#this element is not found in every existing exam paper record
# this is defined in yaml
# return standard term from approved authority list
def get_qualification_level_term(searchterm)
#gonna make this general to include where the existing record doesnt contain 'level' data. this might mean the same level gets added twice of course - cant really help that, the data is too variant. perhaps only add each one once?
searchterm = searchterm.downcase

puts "search  term for degree level was " + searchterm

#brackets essential to avoid false  positives
masters = ['masters','(ma)','(msc)','(mres)','(mphil)','(meng)','(mphys)','(mchem)','(mmath)','(menv)','(llm)','(MNursing)'] 
#bachelors = ['bachelors','bachelor','batchelors', 'batchelor','bsc','ba','bphil','beng','llb']
bachelors = ['bachelor', 'batchelor','(bsc)','(ba)','(bphil)','(beng)','(llb)']
diplomas = ['diploma','(dip', '(dip', 'diploma (dip)','(pgdip)']
lower_diplomas = ['diphe'] #will have to cross check against this as some diplomas are post grad, some lower level
doctoral = ['(phd)','doctor of philosophy (phd)','(scd)']
#prepare this for when we get the agreed mapping - certain terms are obviously similar
cefr = ['cefr'] #I reckon all the stuff including CEFR will be the same
foundation = ['foundation'] #I reckon all the stuff including foundation will be the same. quite a few of these, across a few disciplines eg electronics, no obvious level
part_11_exam = ['part 11a examination', 'Part 11b examination']#just a few, all dept of electronics.

standardterms = []

#its possible there may be multiple matches of the same level for a single term, so make sure we only add it once per search term -eg diploma (dip)
masters.each do |m|
	if searchterm.include? m
	puts "it  found masters for " + m
		if !standardterms.include? 'Masters (Postgraduate)'
			standardterms.push('Masters (Postgraduate)')
		end	
	end
end
bachelors.each do |b|
	if searchterm.include? b
	puts "it  found bachelor for " + b
		if !standardterms.include? 'Bachelors (Undergraduate)'
			standardterms.push('Bachelors (Undergraduate)')
		end			
	end
end
diplomas.each do |d|
	if searchterm.include? d
	puts "it  found diploma for " + d
		#standardterms.push('Diplomas (Postgraduate)')
		if !standardterms.include? 'Diplomas (Postgraduate)'
			standardterms.push('Diplomas (Postgraduate)')
		end	
	end
end
doctoral.each do |dr|
	if searchterm.include? dr
		#standardterms.push('Doctoral (Postgraduate)')
		if !standardterms.include? 'Doctoral (Postgraduate)'
			standardterms.push('Doctoral (Postgraduate)')
		end	
	end
end
cefr.each do |c|
	if searchterm.include? c
		puts "standard term for "+ searchterm + "not yet defined"
	end
end
foundation.each do |f|
	if searchterm.include? f
		puts "standard term for "+ searchterm + "not yet defined"
	end
end
part_11_exam.each do |p|
	if searchterm.include? p
		puts "standard term for "+ searchterm + "not yet defined"
	end
end

#standardterm="unfound"
=begin
standardterms = []
if masters.include? searchterm
	standardterms.push('Masters (Postgraduate)')
elsif bachelors.include? searchterm
	standardterms.push('Bachelors (Undergraduate)')
elsif diplomas.include? searchterm
puts "success with test for diploma"
	standardterms.push('Diplomas (Postgraduate)')
elsif doctoral.include? searchterm
	standardterms.push('Doctoral (Postgraduate)')
elseif cefr.include? searchterm
    puts "standard term for "+ searchterm + "not yet defined"
elseif foundation.include? searchterm
    puts "standard term for "+ searchterm + "not yet defined"
elseif part_11_exam.include? searchterm
    puts "standard term for "+ searchterm + "not yet defined"
end
=end

approved_terms = []
standardterms.each do |st|
	#pass the id, get back the term. in this case both are currently identical
	auth = Qa::Authorities::Local::FileBasedAuthority.new('qualification_levels')
	approved_terms.push(auth.find(st)['term'])
end

puts "size of returned level terms was " +  approved_terms.length.to_s
return approved_terms
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
# see https://wiki.york.ac.uk/display/dlib/Cataloguing+exam+papers and  http://authorities.loc.gov/cgi-bin/Pwebrecon.cgi?Search_Arg=University+of+York&Search_Code=NHED_&PID=N-xo2_UKwOcdvDBzaktyDy18W_Uhp&SEQ=20171101100058&CNT=100&HIST=1
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


need to handle the following additional department string
University of York. Language for All
Core Knowledge, Values and Engagement Skills  (this appears to be health sciences, did a search. confirmed with metadata team)
University of York. Dept. of Biochemistry   #confirmed this should map to the biology department
=end
	loc = stringtomatch.downcase  #get rid of case inconsistencies
	if loc.include? "reconstruction"
		preflabels.push("University of York. Post-war Reconstruction and Development Unit")
	elsif loc.include? "applied human rights" #at top so looks for single subjects later
		preflabels.push("University of York. Centre for Applied Human Rights")
	elsif loc.include? "health economics" #at top so looks for single subjects later
		preflabels.push("University of York. Centre for Health Economics")
	elsif loc.include? "lifelong learning" #at top so looks for single subjects later
		preflabels.push("University of York. Centre for Lifelong Learning")
	elsif loc.include? "medieval studies" #at top so looks for single subjects later
		preflabels.push("University of York. Centre for Medieval Studies")
	elsif loc.include? "renaissance" #at top so looks for single subjects later
		preflabels.push("University of York. Centre for Renaissance and Early Modern Studies")
	elsif loc.include? "reviews" #at top so looks for single subjects later
		preflabels.push("University of York. Centre for Reviews and Disseminations")
	elsif loc.include? "women" #at top so looks for single subjects later
		preflabels.push("University of York. Centre for Women's Studies")
	elsif loc.include? "languages for all" 
		preflabels.push("University of York. Languages for All")
	elsif loc.include? "school of social and political science"#at top so looks for single subjects later
	    preflabels.push("University of York. School of Social and Political Science")
	elsif loc.include? "school of politics economics and philosophy" #at top so looks for single subjects later
	    preflabels.push("University of York. School of Politics Economics and Philosophy")
	elsif loc.include? "economics and related" #at top so looks for single subjects later
	    preflabels.push( "University of York. Department of Economics and Related Studies")	
	elsif loc.include? "economics and philosophy" #at top so looks for single subjects later
		preflabels.push("University of York. School of Politics Economics and Philosophy") 
	elsif loc.include? "departments of english and history of art"   #damn! two departments to return! MUST precede history of art
	    preflabels.push( "University of York. Department of English and Related Literature")
		preflabels.push("University of York. Department of History of Art")
	elsif loc.include? "history of art" #at top so looks for history later. but below english and history of art!
	    preflabels.push("University of York. Department of History of Art") 	
	elsif loc.include? "electronic" 
		preflabels.push("University of York. Department of Electronic Engineering")
	elsif loc.include? "theatre" 
		preflabels.push("University of York. Department of Theatre, Film and Television")
	elsif loc.include? "physics" 
		preflabels.push("University of York. Department of Physics")
	elsif loc.include? "computer" 
		preflabels.push("University of York. Department of Computer Science")	
	elsif loc.include? "psychology" 
		preflabels.push("University of York. Department of Psychology")
	elsif loc.include? "law" 
		preflabels.push("University of York. York Law School") 
	elsif loc.include? "mathematics"
		preflabels.push("University of York. Department of Mathematics") 
	elsif loc.include? "advanced architectural"
	    preflabels.push("University of York. Institute of Advanced Architectural Studies")		
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
	elsif loc.include? "music"
	    preflabels.push( "University of York. Department of Music")
	elsif loc.include? "archaeology"
	    preflabels.push( "University of York. Department of Archaeology")
	elsif loc.include? "biology"
	    preflabels.push( "University of York. Department of Biology")
	elsif loc.include? "biochemistry"
	    preflabels.push( "University of York. Department of Biology") #confirmed with metadata team
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
	elsif loc.include? "hull"
	    preflabels.push("Hull York Medical School")
	elsif loc.include? "international pathway"
	    preflabels.push("University of York. International Pathway College")
	elsif loc.include? "school of criminology"
	    preflabels.push("University of York. School of Criminology")	
	elsif loc.include? "natural sciences"
	    preflabels.push("University of York. School of Natural Sciences")
	elsif loc.include? "environment"
	    preflabels.push("University of York. Environment")	
	end
	return preflabels
end

# this returns the  correct preflabel to be used when calling get_resource_id to get the object ref for the degree
# its a separate method as multiple variants map to the same preflabel/object. it really can only have one return - anything else would be nonsense. its going to be quite complex as some cross checking accross the various types may be  needed
# type_array will be an array consisting of all the types for an object!
def get_qualification_name_preflabel(type_array)
#how to handle? there may be multiple qualification names
#have updated the unqueried qualifications, need to do the others. need to update qual authorities and also to update the mappings for the postgrad diplomas


#Arrays of qualification name variants
#grabbed nursing ma name from https://www.york.ac.uk/healthsciences/study/
#Bachelor of Arts (MA) is a genuine variant that I assume to be a mistake (query sent to Ilka)
artBachelors = ['Batchelor of Arts (BA)', '"Bachelor of Arts (BA),"', 'BA', 'Bachelor of Arts (BA)','Bachelor of Art (BA)', 'Bachelor of Arts', 'Bachelor of Arts (MA)']
artsByResearch = ['Master of Arts by research (MRes)', '"Master of Arts, by research (MRes)"' ]
scienceByResearch = ['Master of Science by research (MRes)', '"Master of Science, by research (MRes)"' ]
#Bachelor of Science (MSc) is a genuine variant that I assume to be a mistake, as is Bachelor of Science (BA)
scienceBachelors = ['Batchelor of science (BSc)', 'Bachelor of Science (BSc)', '"Bachelor of Science (BSc)"', 'BSc', 'Bachelor of Science (BA)','Bachelor of Science (BSc )','Bachelor of Science', 'Bachelor of Science (Bsc)','Bachelor of Science (MSc)']
philosophyBachelors = ['Bachelor of Philosophy (BPhil)', 'BPhil']
engineeringBachelors = ['Bachelor of Engineering (BEng)', 'Bachelor of Engineering']
lawBachelors = ['Bachelor of Laws (LLB)']

mathMasters = ['Master of Mathematics (MMath)','Master of Mathematics (MMAth)']
chemistryMasters = ['Master of Chemistry (MChem)']
scienceMasters = ['Master of Science (MSc.)', '"Master of Science (MSc),"',"'Master of Science (MSc)",'Master of Science (MSc)','MSc', 'Master of Science']
physicsMasters = ['Master of Physics (MPhys)']
philosophyMasters = ['Master of Philosophy (MPhil)','MPhil']
nursingMasters = ['Master of Nursing','Master of Nursing (MNursing)','(MNursing)' ]
artMasters = ['Master of Arts (MA)', 'Master of Arts', 'Master of Art (MA)', 'MA (Master of Arts)','Masters of Arts (MA)', 'MA']
lawMasters = ['Master of Laws (LLM)']
engineeringMasters = ['Master of Engineering (BEng)', 'Master of Engineering (MEng']
envMasters = ['MEnv']
publicAdminMasters = ['Master of Public Administration (MPA)']
researchMasters = ['Master of Research (Mres)','Master of Research (MRes)','Mres','MRes']#this is the only problematic one
#the variant single quote character in  Conservation Studies is invalid and causes invalid multibyte char (UTF-8) error so  handled this in nokogiri open document call. however we also need to ensure the resulting string is included in the lookup array so the match will still be found. this means recreating it and inserting it into the array
not_valid = "Postgraduate Diploma in ‘Conservation Studies’ (PGDip)"
valid_now = not_valid.encode('UTF-8', :invalid => :replace, :undef => :replace)
#pgDiplomas = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', 'Postgraduate Diploma in Medieval Studies (PGDip)','PGDip', 'Diploma','(Dip', '(Dip', 'Diploma (Dip)', valid_now] 
pgDiplomas = ['PGDip', 'Diploma','(Dip', 'Dip', 'Diploma (Dip)','(Dip']
medievalDiplomas = ['Postgraduate Diploma in Medieval Studies (PGDip)']
#conservationDiplomas = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', 'Postgraduate Diploma in Medieval Studies (PGDip)','PGDip', 'Diploma','(Dip', '(Dip', 'Diploma (Dip)', valid_now] 
conservationDiplomas = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', valid_now] #this dealt with an encoding problem in certain records
dipHEs = ['Diploma of Higher Education (DipHE)']
cpds = ['Continuing Professional Development (CPD)']
pgcerts = ['Postgraduate Certificate (PgCert)']
pgces = ['Postgraduate Certificate in Education (PGCE)']
philosophyDoctorates = ['Doctor of Philosophy (PhD)']
pgMedicalCerts = ['Postgraduate Certificate in Medical Education (PGCert)']
scienceDoctorates = ['Doctor of Science (ScD)']

#prepare this for when we get the agreed mapping - certain terms are obviously similar
cefrA1 = ['A1 of the CEFR', 'A1 of CEFR']
cefrA1A2 = ['A1/A2 of the CEFR'] 
cefrB2 = ['B2 of the CEFR']
cefrB2C1 = ['B2/C1 of the CEFR'] 
cefrC1C2 = ['C1/C2 of CEFR','C1/C2 of the CEFR'] 
foundation = ['Foundation Year', 'Foundation Year Stage 0'] #I reckon all the stuff including foundation will be the same. quite a few of these, across a few disciplines eg electronics, no obvious level
part_11A_exam = ['Part IIA Examination']
part_11B_exam = [ 'Part IIB Examination']


qualification_name_preflabels = [] 

type_array.each do |t,|	    #loop1
	type_to_test = t.to_s
	#outer loop tests for creation of qualification_name_preflabel			 
		if artBachelors.include? type_to_test #loop2a
		 qualification_name_preflabels.push("Bachelor of Arts (BA)")
		elsif philosophyBachelors.include? type_to_test
		 qualification_name_preflabels.push("Bachelor of Philosophy (BPhil)")
		elsif scienceBachelors.include? type_to_test
		 qualification_name_preflabels.push("Bachelor of Science (BSc)")	
		elsif engineeringBachelors.include? type_to_test
		 qualification_name_preflabels.push("Bachelor of Engineering (BEng)")
        elsif lawBachelors.include? type_to_test
		 qualification_name_preflabels.push("Bachelor of Laws (LLB)")
		elsif artMasters.include? type_to_test 
		 qualification_name_preflabels.push("Master of Arts (MA)")
		elsif artsByResearch.include? type_to_test
		 qualification_name_preflabels.push("Master of Arts by Research (MRes)")
		elsif philosophyMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Philosophy (MPhil)")
		elsif scienceMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Science (MSc)")
		elsif scienceByResearch.include? type_to_test
		 qualification_name_preflabels.push("Master of Science by Research (MRes)")
		elsif engineeringMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Engineering (MEng)")
		elsif physicsMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Physics (MPhys)")
		elsif publicAdminMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Public Administration (MPA)")
		elsif chemistryMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Chemistry (MChem)")
	    elsif mathMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Mathematics (MMath)")  
		elsif envMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Environmental Science (MEnv)")
		elsif lawMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Laws (LLM)")
		elsif nursingwMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Nursing (MNursing)")
		elsif conservationDiplomas.include? type_to_test
		 qualification_name_preflabels.push("Postgraduate Diploma in Conservation Studies (PGDip)")
		elsif medievalDiplomas.include? type_to_test
		 qualification_name_preflabels.push("Postgraduate Diploma in Medieval Studies (PGDip)")
		#this is more general so crucial it is tested AFTER the more specific diplomas 
		elsif pgDiplomas.include? type_to_test
		 qualification_name_preflabels.push("Postgraduate Diploma (PGDip)")
		elsif pgces.include? type_to_test
		 qualification_name_preflabels.push("Postgraduate Certificate in Education (PGCE)")
		elsif pgMedicalCerts.include? type_to_test
		 qualification_name_preflabels.push("Postgraduate Certificate in Medical Education (PGCert)")
		elsif philosophyDoctorates.include? type_to_test
		 qualification_name_preflabels.push("Doctor of Philosophy (PhD)")
		elsif scienceDoctorates.include? type_to_test
		 qualification_name_preflabels.push("Doctor of Science (ScD)")
		elsif cpds.include? type_to_test
		 qualification_name_preflabels.push("Continuing Professional Development (CPD)")
		elsif dipHEs.include? type_to_test
		 qualification_name_preflabels.push("Diploma of Higher Education (DipHE)")
		elsif pgcerts.include? type_to_test
		 qualification_name_preflabels.push("Postgraduate Certificate (PgCert)")
		#preparation for  preflabel assignment when defined
		#order importand, look for most precise first
		elsif cefrA1A2.include? type_to_test
		 puts "preflabel not yet defined for cefrA1A2"
		elsif cefrA1.include? type_to_test
		 puts "preflabel not yet defined for cefrA1"
		elsif cefrB2C1.include? type_to_test
		 puts "preflabel not yet defined for cefrB2C1"
		elsif cefrC1C2.include? type_to_test
		 puts "preflabel not yet defined for cefrC1C2"
		elsif cefrB2.include? type_to_test
		 puts "preflabel not yet defined for cefrB2"
		elsif foundation.include? type_to_test
		 puts "preflabel not yet defined for foundation"
		elsif part_11A_exam.include? type_to_test
		 puts "preflabel not yet defined for part_11A_exam"
		elsif part_11B_exam.include? type_to_test
		 puts "preflabel not yet defined for part_11B_exam"
	end #end loop1
		
	#not found? check for plain research masters without arts or science specified (order of testing here is crucial) (required for theses)
	      if qualification_name_preflabels.length <= 0  #loop2
			if researchMasters.include? type_to_test #loop 3 not done with main list as "MRes" may be listed as separate type as well as a more specific type
				qualification_name_preflabels.push("Master of Research (MRes)")
			end#end loop3
		end   #'end loop 2
	end #end loop1
	return qualification_name_preflabels
end  #end get_qualification_name_preflabel 

def get_standard_language(searchterm)
	s = searchterm.titleize
	auth = Qa::Authorities::Local::FileBasedAuthority.new('languages')
	approved_language = auth.search(s)[0]['id']
end

# will need to expand this for other collections, but not Theses, as all have same rights
def get_standard_rights(searchterm)
if searchterm.include?("yorkrestricted")
  term = 'York Restricted'
else
  term = 'undetermined'
end
	auth = Qa::Authorities::Local::FileBasedAuthority.new('licenses') 
	rights = auth.search(term)[0]['id']
end

#utility method to list all the datastream IDs to a text file
#by calling in the migration method we can then do search and replaces to output all unique DS IDs in a collection of fedora objects
#the dslistfile param is the  filename to allow different lists for different collections if required
#the idname should consist purely of the ID, without any  version number. gets called by list_all_ds_in_set
def write_to_ds_list(dslistfile,idname)
listfile = File.open( "/home/dlib/lists/uniqueDSlists/"+ dslistfile, "a")
	listfile.puts( idname)
	listfile.close	
end

#utility method to list all the datastream LABELs to a text file
#by calling in the migration method we can then do search and replaces to output all unique DS LABELs in a collection of fedora objects
#the dslistfile param is the  filename to allow different lists for different collections if required
#the labelname should consist purely of the LABEL, without any  version number. gets called by list_all_labels_in_set
def write_to_labels_list(labellistfile,labelname)
listfile = File.open( "/home/dlib/lists/uniqueDSlists/"+ labellistfile, "a")
	listfile.puts( labelname)
	listfile.close	
	
end

#rake migration_tasks:list_datastream_labels,[/home/dlib/testfiles/foxml,labels_list.txt]
def list_all_labels_in_set(foxmlpath,outputfilename)
labelmap = []
Dir.foreach(foxmlpath)do |item|
# we dont want to try and act on the current and parent directories
next if item == '.' or item == '..'
    path = foxmlpath +"/" + item.to_s
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
	# doesnt resolve nested namespaces, this fixes that
    ns = doc.collect_namespaces	
	ds_labels = doc.xpath("//foxml:datastreamVersion[@LABEL]",ns)
	ds_labels.each { |label| 
		labelname = label.attr('LABEL')
			if !labelmap.include? labelname
				labelmap.push(labelname)			
			end	 
	}	
end
	labelmap.each { |label| 
		write_to_labels_list(outputfilename,label) 
	}
	doc = nil
	puts "all done, written to /home/dlib/lists/uniqueDSlists/" + outputfilename
end#end method


#rake migration_tasks:list_datastreams[/home/dlib/testfiles/foxml,UG-ds_list.txt]
def list_all_ds_in_set(foxmlpath,outputfilename)
puts "listing all ds  in "+foxmlpath
idmap = []
Dir.foreach(foxmlpath)do |item|
# we dont want to try and act on the current and parent directories
next if item == '.' or item == '..'
    path = foxmlpath +"/" + item.to_s
	
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}	
	# doesnt resolve nested namespaces, this fixes that
    ns = doc.collect_namespaces	
	ds_ids = doc.xpath("//foxml:datastream[@ID]",ns)
	ds_ids.each { |id| 
		idname = id.attr('ID')		
			if !idmap.include? idname
				idmap.push(idname)			
			end	 
	}	
end
	idmap.each { |id| 
		write_to_ds_list(outputfilename,id) 
	}
	doc = nil
	puts "all done"
end#end method


# check values of 'dc_type' as some of these are used for lookups, so we need to know all possible variants (there are many)
#rake migration_tasks:list_dc_type_values[/home/dlib/testfiles/foxml,dc_type_list.txt]
def list_dc_type_values(foxmlpath,outputfilename)
   
	valuemap= []
	Dir.foreach(foxmlpath)do |item|	
		next if item == '.' or item == '..'
		puts "now on " + item.to_s
		path = foxmlpath +"/" + item.to_s
		doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
		ns = doc.collect_namespaces
		#not gonna worry about versions on this occasion, only expecting one
		dctypes = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/foxml:xmlContent/oai_dc:dc/dc:type/text()",ns)
		#puts "dcypes size was " + dctypes.size.to_s
		dctypes.each { |t|
			if !valuemap.include? t.to_s
			   valuemap.push(t.to_s)			
			end
		}
		
	end
	valuemap.each {|v| 
		listfile = File.open( "/home/dlib/lists/uniqueDSlists/"+ outputfilename, "a")
				listfile.puts(v)
				listfile.close
	}
	doc = nil
end #end method


# check values of 'dc_creator' to get department values
#rake migration_tasks:list_dc_creator_values[/home/dlib/testfiles/foxml,dc_creator_list.txt]
def list_dc_creator_values(foxmlpath,outputfilename)
   
	valuemap= []
	Dir.foreach(foxmlpath)do |item|	
		next if item == '.' or item == '..'
		puts "now on " + item.to_s
		path = foxmlpath +"/" + item.to_s
		doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
		ns = doc.collect_namespaces
		#not gonna worry about versions on this occasion, only expecting one
		dccreators = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns)
		#puts "dcypes size was " + dctypes.size.to_s
		dccreators.each { |c|
		#puts "t was:" + t.to_s + ":"
			if !valuemap.include? c.to_s
			   valuemap.push(c.to_s)			
			end
		}
		
	end
	valuemap.each {|v| 
		listfile = File.open( "/home/dlib/lists/uniqueDSlists/"+ outputfilename, "a")
				listfile.puts(v)
				listfile.close
	}
	doc = nil
end #end method

#possibly a 'one-of' to check values of 'format' but could be useful for others too
def check_format_values(foxmlpath,outputfilename)
   
	valuemap= []
	Dir.foreach(foxmlpath)do |item|	
		next if item == '.' or item == '..'
		path = foxmlpath +"/" + item.to_s
		doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
		ns = doc.collect_namespaces
		#not gonna worry about versions on this occasion, only expecting one
		formats = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/foxml:xmlContent/oai_dc:dc/dc:format/text()",ns)
		formats.each { |format|
			if !valuemap.include? format
			   valuemap.push(format)			
			end
		}
		
	end
	valuemap.each {|v| 
		listfile = File.open( "/home/dlib/lists/uniqueDSlists/"+ outputfilename, "a")
				listfile.puts(v)
				listfile.close
	}
	doc = nil
end #end method

#suspect this wont work as would actually fail at an early stage in nokogiri when it first tries to open it
# check coding valid - run against file list before migration. 
def check_encoding(foxmlpath,outputfilename)
#test it against just the likely elements
#dc:description, dc:title, dc:subject, dc:creator,  dc:abstract
valuemap= []
	Dir.foreach(foxmlpath)do |item|	
		next if item == '.' or item == '..'
		puts "now on " + item.to_s
		path = foxmlpath +"/" + item.to_s		
		
		doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
		ns = doc.collect_namespaces
		#not gonna worry about versions on this occasion, only expecting one
		#get current dc version
		nums = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion/@ID",ns)	
		all = nums.to_s
		current = all.rpartition('.').last 
		currentVersion = 'DC.' + current
		
		#test = "\x999"
		#test.force_encoding "utf-8"
		#if !test.valid_encoding?
		# puts "test 1 failed, as was intended"
		#end
		#titles
		dctitles = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:title/text()",ns)
		dctitles.each { |t|
			#t= t.to_s + "\x99999"   #this proved an invalid sequence would be found
			t= t.to_s
			t.force_encoding "utf-8"
			if !t.valid_encoding?			
			   valuemap.push("dc:title " + t + " in " + item.to_s)			
			end
		} 
		
		#creators
		dccreators = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:creator/text()",ns)
		dccreators.each { |c|
			c= c.to_s
			c.force_encoding "utf-8"
			if !c.valid_encoding?
			   valuemap.push(valuemap.push("dc:creator " + c + " in " + item.to_s))
			end
		} 
		
		#subject
		dcsubjects = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:subject/text()",ns)
		dcsubjects.each { |s|
			s= s.to_s
			s.force_encoding "utf-8"
			if !s.valid_encoding?
			   valuemap.push(valuemap.push("dc:subject " + s + " in " + item.to_s))		
			end
		} 
		
		#abstract
		dcabstracts = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:abstract/text()",ns)
		dcabstracts.each { |a|
		    a= a.to_s
			a.force_encoding "utf-8"
			if !a.valid_encoding?
			   valuemap.push(valuemap.push("dc:abstract " + a + " in " + item.to_s))		
			end
		} 
		
		#description
		dcdescriptions = doc.xpath("//foxml:datastream[@ID='DC']/foxml:datastreamVersion[@ID='#{currentVersion}']/foxml:xmlContent/oai_dc:dc/dc:description/text()",ns)
		#puts "dcypes size was " + dctypes.size.to_s
		dcdescriptions.each { |d|
			d = d.to_s
			d.force_encoding "utf-8"
			if !d.valid_encoding?
			   valuemap.push(valuemap.push("dc:description " + d + " in " + item.to_s))
			end
		} 
		
	end #end of Dir.foreach
	
	valuemap.each {|v| 
		listfile = File.open( "/home/dlib/lists/"+ outputfilename, "a")
				listfile.puts(v)
				listfile.close
	} #end of valuemap.each
	
	doc = nil
end #end method

#see how many exam papers dont have a main exam paper datastream!
#rake migration_tasks:list_missing_exam_ds[/home/dlib/testfiles/foxml/test,noexampapers.txt]
def check_has_main(foxmlpath,outputfilename)

listfile = File.open( "/home/dlib/lists/uniqueDSlists/"+ outputfilename, "a")
Dir.foreach(foxmlpath)do |item|
# we dont want to try and act on the current and parent directories
next if item == '.' or item == '..'
dsmap = []
    path = foxmlpath +"/" + item.to_s
	puts "working on " + item.to_s
	doc = File.open(path){ |f| Nokogiri::XML(f, Encoding::UTF_8.to_s)}
    ns = doc.collect_namespaces	
	ds_ids = nil
	ds_ids = doc.xpath("/foxml:digitalObject/foxml:datastream[@ID]",ns)  #KALE
	ds_ids.each { |id| 	
		idname = id.attr('ID')
		idname = idname.to_s
		idstate = id.attr('STATE')
		if !dsmap.include? idname
			if idstate.to_s == "A"
				dsmap.push(idname)
			end
		end	
	}	
	if !dsmap.include? "EXAM_PAPER"
				puts "this record had no EXAM_PAPER"				
				listfile.puts("no active EXAM_PAPER in " + item)
	end	
end
    listfile.close
	doc = nil
	puts "all done, written to /home/dlib/lists/uniqueDSlists/" + outputfilename
end #end of check_has_main



end # end of class
