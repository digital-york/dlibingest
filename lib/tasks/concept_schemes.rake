namespace :concept_schemes do
  require 'csv'

  SOLR = 'http://localhost:8983/solr/development'

  task a: :environment do
    solr = RSolr.connect :url => SOLR
    response = solr.get 'select', :params => {
        :q=>'preflabel_tesim:qualification_names AND has_model_ssim:Dlibhydra::ConceptScheme',
        :start=>0,
        :rows=>10
    }
    response["response"]["docs"].first['id']
  end

  desc "load_terms"
  task load_terms: :environment do

    path = Rails.root + 'lib/'
    # .csv files should exist in the specified path
    #list = ['qualification_names']
    list = ['subjects','qualification_names','journals']
    list.each do |i|

      puts 'Creating the Concept Scheme'

      begin
        @scheme = ''
        solr = RSolr.connect :url => SOLR
        response = solr.get 'select', :params => {
            :q=>"preflabel_tesim:#{i} AND has_model_ssim:Dlibhydra::ConceptScheme",
            :start=>0,
            :rows=>10
        }

        if response["response"]["numFound"] == 0
          @scheme = Dlibhydra::ConceptScheme.new
        else
          @scheme = Dlibhydra::ConceptScheme.find(response["response"]["docs"].first['id'])
        end
        @scheme.preflabel = i
        @scheme.save
        puts "Concept scheme for #{i} created at #{@scheme.id}"
      rescue
        puts $!
      end

      puts 'Processing ' + i

      arr = CSV.read(path + "assets/lists/#{i}.csv")
      arr = arr.uniq # remove any duplicates

      arr.each do |c|
        begin
          h = Dlibhydra::Concept.new
          h.preflabel = c[0].strip
          h.altlabel = [c[2].strip] unless c[2].nil?
          h.same_as = [c[1].strip] unless c[1].nil?
          h.concept_scheme = @scheme
          h.save
          @scheme.concepts << h
          @scheme.save
          puts "Term for #{c[0]} created at #{h.id}"
        rescue
          puts $!
        end
      end
    end
    puts 'Finished!'
  end

  desc 'load_depts'
  task load_depts: :environment do

    path = Rails.root + 'lib/'
    # .csv files should exist in the specified path
    # 'departments',
    list = ['current_organisations','departments']
    list.each do |i|

      puts 'Creating the Concept Scheme'

      begin
        solr = RSolr.connect :url => SOLR
        response = solr.get 'select', :params => {
            :q=>"preflabel_tesim:#{i} AND has_model_ssim:Dlibhydra::ConceptScheme",
            :start=>0,
            :rows=>10
        }
        if response["response"]["numFound"] == 0
          @scheme = Dlibhydra::ConceptScheme.new
        else
          @scheme = Dlibhydra::ConceptScheme.find(response["response"]["docs"].first['id'])
        end
        @scheme.preflabel = i
        @scheme.save
        puts "Concept scheme for #{i} created at #{@scheme.id}"
      rescue
        puts $!
      end

      puts 'Processing ' + i

      arr = CSV.read(path + "assets/lists/#{i}.csv")
      arr = arr.uniq # remove any duplicates

      arr.each do |c|
        begin
          h = Dlibhydra::CurrentOrganisation.new
          h.preflabel = c[0].strip
          h.name = c[0].strip
          h.altlabel = [c[2].strip] unless c[2].nil?
          h.same_as = [c[1].strip] unless c[1].nil?
          h.concept_scheme = @scheme
          h.save
          @scheme.current_organisations << h
          if i == 'departments'
           @scheme.departments << h
          end
          @scheme.save
          puts "Term for #{c[0]} created at #{h.id}"
        rescue
          puts $!
        end
      end
    end
    puts 'Finished!'
  end
end
