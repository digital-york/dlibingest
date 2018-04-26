# encoding: UTF-8
require 'nokogiri'
require 'open-uri'
require 'dlibhydra'
require 'csv'

# methods to create the  collection structure and do migrations
class MetadataChecks
include ::Dlibhydra
include ::CurationConcerns
include ::Hydra

def say_hi
puts "hi"
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


#utility method to list all the datastream LABELs to a text file
#by calling in the migration method we can then do search and replaces to output all unique DS LABELs in a collection of fedora objects
#the dslistfile param is the  filename to allow different lists for different collections if required
#the labelname should consist purely of the LABEL, without any  version number. gets called by list_all_labels_in_set
def write_to_labels_list(labellistfile,labelname)
listfile = File.open( "/home/dlib/lists/uniqueDSlists/"+ labellistfile, "a")
	listfile.puts( labelname)
	listfile.close	
	
end

#rake migration_tasks:list_datastream_labels[/home/dlib/testfiles/foxml,labels_list.txt]
#if need to include quotesor other such characters use excapes within quoted text thus "LABEL=\"Metadata"\"
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
#rake migration_tasks:list_invalid_utf8[/home/dlib/testfiles/foxml,invalid_utf8.txt]
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
