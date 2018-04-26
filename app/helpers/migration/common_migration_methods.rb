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
# return standard term from approved authority list. NOTE searchterms are all down cased.
def get_qualification_level_term(searchterm)
#gonna make this general to include where the existing record doesnt contain 'level' data. this might mean the same level gets added twice of course - cant really help that, the data is too variant. perhaps only add each one once?
searchterm = searchterm.downcase
#puts "search  term for degree level was " + searchterm
#brackets essential to avoid false  positives
masters = ['masters','(ma)','(msc)','(mres)','(mphil)','(meng)','(mphys)','(mchem)','(mmath)','(menv)','(llm)','(mnursing)'] 
bachelors = ['bachelor', 'batchelor','(bsc)','(ba)','(bphil)','(beng)','(llb)']
diplomas = ['diploma','(dip', '(dip', 'diploma (dip)','(pgdip)']
lower_diplomas = ['diphe', 'diploma of higher education (diphe)'] 
doctoral = ['(phd)','doctor of philosophy (phd)','(scd)']
cefr = ['cefr'] 
foundation = ['foundation']

standardterms = []

#its possible there may be multiple occurences of the same level for a single term, so make sure we only add it once per search term -eg diploma (dip)
masters.each do |m|
	if searchterm.include? m
		if !standardterms.include? 'Masters (Postgraduate)'
			standardterms.push('Masters (Postgraduate)')
		end	
	end
end
bachelors.each do |b|
	if searchterm.include? b
		if !standardterms.include? 'Bachelors (Undergraduate)'
			standardterms.push('Bachelors (Undergraduate)')
		end			
	end
end
lower_diplomas.each do |ld|
	if searchterm.include? ld
		if !standardterms.include? 'Diplomas (other)'		
			standardterms.push('Diplomas (other)')
		end
    else
        #only look for the higher diploma if you dont find the lower diploma	
		diplomas.each do |d|
		if searchterm.include? d
			if !standardterms.include? 'Diplomas (Postgraduate)'
				standardterms.push('Diplomas (Postgraduate)')
			end	
		end
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
		if !standardterms.include? 'CEFR Module'
			standardterms.push('CEFR Module')
		end	
	end
end
foundation.each do |f|
	if searchterm.include? f
		if !standardterms.include? 'Foundation'
			standardterms.push('Foundation')
		end	
	end
end


approved_terms = []
standardterms.each do |st|
	#pass the id, get back the term. in this case both are currently identical
	auth = Qa::Authorities::Local::FileBasedAuthority.new('qualification_levels')
	approved_terms.push(auth.find(st)['term'])
end


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
	    preflabels.push("University of York. Environment Department")	
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
#doctorates
lettersDoctorates = ['Doctor of Letters (DLitt)','Doctor of Letters','DLitt']
musicDoctorates = ['Doctor of Music (DMus)','Doctor of Music','DMus']
scienceDoctorates = ['Doctor of Science (ScD)','Doctor of Science','ScD']
engineeringDoctorates = ['Doctor of Engineering (EngD)','Doctor of Engineering','EngD']
medicalDoctoratesbyPubs = ['Doctor of Medicine by publications (MD)','Doctor of Medicine by publications']
medicalDoctorates = ['Doctor of Medicine (MD)','MD']
philosophyDoctoratesbyPubs = ['Doctor of Philosophy by publications (PhD)','Doctor of Philosophy by publications']
philosophyDoctorates = ['Doctor of Philosophy (PhD)','PhD'] 
#masters
philosophyMastersbyPubs = ['Master of Philosophy by publications (MPhil)','Master of Philosophy by publications']
philosophyMasters = ['Master of Philosophy (MPhil)','MPhil']
artMastersbyResearch = ['Master of Arts (by research) (MA (by research))','Master of Arts (by research)','(MA (by research)','Master of Arts by research (MRes)']
artMasters = ['Master of Arts (MA)', 'Master of Arts', 'Master of Art (MA)', 'MA (Master of Arts)','Masters of Arts (MA)', 'MA']
scienceMastersbyResearch = ['Master of Science (by research) (MSc (by research))','Master of Science (by research)']
scienceMastersbyThesis = ['Master of Science (by thesis) (MSc (by thesis))','Master of Science (by thesis)','MSc (by thesis)']
scienceMasters = ['Master of Science (MSc.)', '"Master of Science (MSc),"',"'Master of Science (MSc)",'Master of Science (MSc)','MSc', 'Master of Science']
lawsMasters = ['Master of Laws (LLM)','Master of Laws','LLM']
lawMasters = ['Master of Law (MLaw)','Master of Law','MLaw'] #not an error!
publicAdminMasters = ['Master of Public Administration (MPA)','Master of Public Administration','MPA']
biologyMasters = ['Master of Biology (MBiol)','Master of Biology','MBiol']
biochemMasters = ['Master of Biochemistry (MBiochem)','Master of Biochemistry','MBiochem']
biomedMasters = ['Master of Biomedical Science (MBiomedsci)','Master of Biomedical Science','MBiomedsci']
chemistryMasters = ['Master of Chemistry (MChem)','Master of Chemistry','MChem']
engineeringMasters = ['Master of Engineering (MEng)', 'Master of Engineering (MEng','Master of Engineering','MEng']
mathMasters = ['Master of Mathematics (MMath)','Master of Mathematics (MMAth)','Master of Mathematics','MMath']
physicsMasters = ['Master of Physics (MPhys)','Master of Physics','MPhys']
psychMasters = ['Master of Psychology (MPsych)','Master of Psychology','MPsych']
envMasters = ['Master of Environment (MEnv)','Master of Environment','MEnv']
nursingMasters = ['Master of Nursing','Master of Nursing (MNursing)','(MNursing)' ]
publicHealthMasters = ['Master of Public Health (MPH)','Master of Public Health','MPH']
socialworkMasters = ['Master of Social Work and Social Science (MSWSS)','Master of Social Work and Social Science','(MSWSS)']
researchMasters = ['Master of Research (Mres)','Master of Research (MRes)','Mres','MRes']
#the variant single quote character in  Conservation Studies is invalid and causes invalid multibyte char (UTF-8) error so  handled this in nokogiri open document call. however we also need to ensure the resulting string is included in the lookup array so the match will still be found. this means recreating it and inserting it into the array


#bachelors

medicineSurgeryBachelors = ['Bachelor of Medicine, Bachelor of Surgery (MBBS)','Bachelor of Medicine, Bachelor of Surgery','MBBS']
medsciBachelors = ['Bachelor of Medical Science (BMedSci)','Bachelor of Medical Science','BMedSci']
scienceBachelors = ['Batchelor of science (BSc)', 'Bachelor of Science (BSc)', '"Bachelor of Science (BSc)"', 'BSc', 'Bachelor of Science (BA)','Bachelor of Science (BSc )','Bachelor of Science', 'Bachelor of Science (Bsc)','Bachelor of Science (MSc)']
artBachelors = ['Batchelor of Arts (BA)', '"Bachelor of Arts (BA),"', 'BA', 'Bachelor of Arts (BA)','Bachelor of Art (BA)', 'Bachelor of Arts', 'Bachelor of Arts (MA)']
philosophyBachelors = ['Bachelor of Philosophy (BPhil)','Bachelor of Philosophy' ,'BPhil']
engineeringBachelors = ['Bachelor of Engineering (BEng)', 'Bachelor of Engineering','BEng']
lawBachelors = ['Bachelor of Laws (LLB)','Bachelor of Laws','LLB']

#others
foundationDegrees = ['Foundation Degree (FD)','Foundation Degree','FD']
certHEs = ['Certificate of Higher Education (CertHE)','Certificate of Higher Education','CertHE']
dipHEs = ['Diploma of Higher Education (DipHE)','Diploma of Higher Education','DipHE']
gradCerts = ['Graduate Certificate (GradCert)','Graduate Certificate','GradCert']
gradDiplomas = ['Graduate Diploma (GradDip)','Graduate Diploma','GradDip']
uniCerts = ['University Certificate']
foundationCerts = ['Foundation Certificate (F Cert)','Foundation Certificate','F Cert']
foundation = ['Foundation Year', 'Foundation Year Stage 0'] #not neccesarily the same as above
preMasters = ['Pre-Masters']
#the variant single quote character in  Conservation Studies is invalid and causes invalid multibyte char (UTF-8) error so  handled this in nokogiri open document call. however we also need to ensure the resulting string is included in the lookup array so the match will still be found. this means recreating it and inserting it into the array
not_valid = "Postgraduate Diploma in ‘Conservation Studies’ (PGDip)"
valid_now = not_valid.encode('UTF-8', :invalid => :replace, :undef => :replace)
#pgDiplomas = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', 'Postgraduate Diploma in Medieval Studies (PGDip)','PGDip', 'Diploma','(Dip', '(Dip', 'Diploma (Dip)', valid_now] 
pgDiplomas = ['PGDip', 'Diploma','(Dip', 'Dip', 'Diploma (Dip)','(Dip']
medievalDiplomas = ['Postgraduate Diploma in Medieval Studies (PGDip)']
#conservationDiplomas = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', 'Postgraduate Diploma in Medieval Studies (PGDip)','PGDip', 'Diploma','(Dip', '(Dip', 'Diploma (Dip)', valid_now] 
conservationDiplomas = ['Diploma in Conservation Studies', 'Postgraduate Diploma in Conservation Studies ( PGDip)','Postgraduate Diploma in Conservation Studies(PGDip)', valid_now] #this dealt with an encoding problem in certain records
cpds = ['Continuing Professional Development (CPD)','Continuing Professional Development','CPD']
pgces = ['Postgraduate Certificate in Education (PGCE)']
pgMedicalCerts = ['Postgraduate Certificate in Medical Education (PGCert)']
pgcerts = ['Postgraduate Certificate (PgCert)']
cefrs = ['A1 of the CEFR', 'A1 of CEFR','A1/A2 of the CEFR','A2 of the CEFR','A2/B1 of the CEFR','B1/B2 of the CEFR','B2 of the CEFR','B2/C1 of the CEFR','C1 of the CEFR','C2 of the CEFR','C1/C2 of CEFR','C1/C2 of the CEFR']

#all listed now need to do processing. add elsifs, but also CEFR and Foundations need stuff ading to as description, this will need doing in the specific migrator

qualification_name_preflabels = [] 

type_array.each do |t,|	    #loop1
	type_to_test = t.to_s
	#puts "search  term for qualification_name_preflabel was " + type_to_test
	#outer loop tests for creation of qualification_name_preflabel			 
		if lettersDoctorates.include? type_to_test #loop2
		 qualification_name_preflabels.push("Doctor of Letters (DLitt)")
		elsif musicDoctorates.include? type_to_test 
		 qualification_name_preflabels.push("Doctor of Music (DMus)")
		elsif scienceDoctorates.include? type_to_test
		 qualification_name_preflabels.push("Doctor of Science (ScD)")
		elsif engineeringDoctorates.include? type_to_test
		 qualification_name_preflabels.push("Doctor of Engineering (EngD)")
		elsif medicalDoctoratesbyPubs.include? type_to_test
		 qualification_name_preflabels.push("Doctor of Medicine by publications (MD)")
		elsif medicalDoctorates.include? type_to_test
		 qualification_name_preflabels.push("Doctor of Medicine (MD)")
		elsif philosophyDoctoratesbyPubs.include? type_to_test
		 qualification_name_preflabels.push("Doctor of Philosophy by publications (PhD)")
		elsif philosophyDoctorates.include? type_to_test
		 qualification_name_preflabels.push("Doctor of Philosophy (PhD)")
		
		elsif philosophyMastersbyPubs.include? type_to_test
		 qualification_name_preflabels.push("Master of Philosophy by publications (MPhil)") 
		elsif philosophyMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Philosophy (MPhil)")
		elsif artMastersbyResearch.include? type_to_test
		 qualification_name_preflabels.push("Master of Arts (by research) (MA (by research))")		
		elsif artMasters.include? type_to_test 
		 qualification_name_preflabels.push("Master of Arts (MA)")
		elsif scienceMastersbyResearch.include? type_to_test
		 qualification_name_preflabels.push("Master of Science (by research) (MSc (by research))")
		elsif scienceMastersbyThesis.include? type_to_test
		 qualification_name_preflabels.push("Master of Science (by thesis) (MSc (by thesis))")
		elsif scienceMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Science (MSc)")		
		elsif lawsMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Laws (LLM)") 
		elsif lawMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Law (MLaw)")
		elsif publicAdminMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Public Administration (MPA)")
		elsif biologyMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Biology (MBiol)")
		elsif biochemMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Biochemistry (MBiochem)")
		elsif biomedMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Biomedical Science (MBiomedsci)")
		elsif chemistryMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Chemistry (MChem)")
		elsif engineeringMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Engineering (MEng)")
		elsif mathMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Mathematics (MMath)")
		elsif physicsMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Physics (MPhys)")
		elsif psychMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Psychology (MPsych)")
		elsif envMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Environment (MEnv)")
		elsif nursingMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Nursing (MNursing)")
		elsif publicHealthMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Public Health (MPH)")
		elsif socialworkMasters.include? type_to_test
		 qualification_name_preflabels.push("Master of Social Work and Social Science (MSWSS)")
		
		elsif medicineSurgeryBachelors.include? type_to_test 
		 qualification_name_preflabels.push("Bachelor of Medicine, Bachelor of Surgery (MBBS)")
		elsif medsciBachelors.include? type_to_test 
		 qualification_name_preflabels.push("Bachelor of Medical Science (BMedSci)")
		elsif scienceBachelors.include? type_to_test
		 qualification_name_preflabels.push("Bachelor of Science (BSc)")
		elsif artBachelors.include? type_to_test 
		 qualification_name_preflabels.push("Bachelor of Arts (BA)")
		elsif philosophyBachelors.include? type_to_test
		 qualification_name_preflabels.push("Bachelor of Philosophy (BPhil)")		
		elsif engineeringBachelors.include? type_to_test
		 qualification_name_preflabels.push("Bachelor of Engineering (BEng)")
        elsif lawBachelors.include? type_to_test
		 qualification_name_preflabels.push("Bachelor of Laws (LLB)")
		 
		elsif foundationDegrees.include? type_to_test
		 qualification_name_preflabels.push("Foundation Degree (FD)")
		elsif certHEs.include? type_to_test
		 qualification_name_preflabels.push("Certificate of Higher Education (CertHE)")
		elsif dipHEs.include? type_to_test
		 qualification_name_preflabels.push("Diploma of Higher Education (DipHE)")
		elsif gradCerts.include? type_to_test
		 qualification_name_preflabels.push("Graduate Certificate (GradCert)")
		elsif gradDiplomas.include? type_to_test
		 qualification_name_preflabels.push("Graduate Diploma (GradDip)")
		elsif uniCerts.include? type_to_test
		 qualification_name_preflabels.push("University Certificate")
		elsif foundationCerts.include? type_to_test
		 qualification_name_preflabels.push("Foundation Certificate (F Cert)")
		elsif foundation.include? type_to_test
		 qualification_name_preflabels.push("Foundation")
		elsif preMasters.include? type_to_test
		 qualification_name_preflabels.push("Pre-Masters")
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
		elsif cpds.include? type_to_test
		 qualification_name_preflabels.push("Continuing Professional Development (CPD)")		
		elsif pgcerts.include? type_to_test
		 qualification_name_preflabels.push("Postgraduate Certificate (PgCert)")
		#preparation for  preflabel assignment when defined
		#order importand, look for most precise first
		elsif cefrs.include? type_to_test
		 qualification_name_preflabels.push("CEFR Module")		
	end #end 2
		
	#not found? check for plain research masters without arts or science specified (order of testing here is crucial) (required for theses)
	      if qualification_name_preflabels.length <= 0  #loop2a
			if researchMasters.include? type_to_test #loop 3 not done with main list as "MRes" may be listed as separate type as well as a more specific type
				qualification_name_preflabels.push("Master of Research (MRes)")
			end#end loop3
		end   #'end loop 2a
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



end # end of class
