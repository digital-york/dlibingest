# encoding: UTF-8

# methods to create the  collection structure and do migrations
class DateManipulation
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra

def say_hi
puts "hi"
end

#method to ensure date is formatted as a single year yyyy
def normalise_date(unnormalised_date)
#known variants to normalise
# yyyy
#yyyy-mm
#mm-yyyy
#yyyy-yyyy
#dd-mm-yyyy
#yyyy-mm-dd */
normalised = ""
 if  /^[0-9]{4}\Z/.match  #already in correct form.  
	normalised = unnormalised_date
 elsif /^[0-9]{4}-[0-9]{2}\Z/.match #yyyy-mm
	normalised = unnormalised_date[0-4]
 elsif /^[0-9]{2}-[0-9]{4}\Z/.match #mm-yyyy
	normalised = unnormalised_date[3-8]
 elsif /^[0-9]{4}-[0-9]{4}\Z/.match  #yyyy-yyyy 
	normalised = unnormalised_date[5-8]	
 elsif 	/^[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/ #yyyy-mm-dd  (actual order of month/day unimportant)
    normalised = unnormalised_date[0-4]
 elsif 	/^[0-9]{2}-[0-9]{2}-[0-9]{4}\Z/ #mm-dd-yyyy  (actual order of month/day unimportant)	
	normalised = unnormalised_date[6-9]
 else
     #return whatever we've found - its better than nothing
	 normalised = unnormalised_date
 end
    return normalised
end

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
end 


end # end of class
