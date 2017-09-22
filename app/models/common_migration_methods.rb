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





end # end of class
