require 'json'
require 'dlibhydra'
require 'hydra/works'

class WorkflowWorker

  @queue = "workflow"

  def self.perform(message)
    puts 'received message'
    puts message

    begin
      json_s = message.first.to_json
      json = JSON.parse json_s

      creators             = json['creator']
      keywords             = json['keyword']
      rights               = json["rights"]
      subjects             = json["subject"]
      languages            = json["language"]
      departments          = json["department"]
      advisors             = json["advisor"]
      visibility           = json["visibility"]
      title                = json["preflabel"]
      abstract             = json["abstract"]
      qualification_name   = json["qualification_name"]
      qualification_level  = json["qualification_level"]
      date_of_award        = json["date_of_award"]
      awarding_institution = json["awarding_institution"]

      title_array                 = title.split(',')
      creators_array              = creators.split(',')
      keywords_array              = keywords.split(',')
      subjects_array              = subjects.split(',')
#	  rights_array                = rights.split(',')
      languages_array             = languages.split(',')
      departments_array           = departments.split(',')
      advisors_array              = advisors.split(',')
#      visibility_array            = visibility.split(',')
      qualification_name_array    = qualification_name.split(',')
      qualification_level_array   = qualification_level.split(',')
#      date_of_award_array         = date_of_award.split(',')
      awarding_institution_array  = awarding_institution.split(',')

      thesis = Dlibhydra::Thesis.create

      thesis.title      = title_array
#thesis.keyword    = keywords_array
      thesis.keyword    = ['northern misery']
      thesis.rights     = rights
#thesis.language   = languages_array
      thesis.language   = ['en-GB']
#thesis.department = departments_array
#thesis.advisor    = advisors_array
      thesis.qualification_name = qualification_name_array
      thesis.qualification_level = qualification_level_array
      thesis.date_of_award = date_of_award
      thesis.awarding_institution = awarding_institution_array

      thesis.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}),
                            Hydra::AccessControls::Permission.new({:name=>"frank.feng@york.ac.uk", :type=> "person", :access => "edit"})]
      thesis.depositor   = "frank.feng@york.ac.uk"

      thesis.save!
      puts 'saved thesis with id: ' + thesis.id.to_s

      users = Object::User.all #otherwise it will use one of the included modules
      user = users[0]
      puts 'found user'

      fileset = Dlibhydra::FileSet.new


      fileset.title = ['test fileset']
      fileset.permissions = [Hydra::AccessControls::Permission.new({:name=> "public", :type=>"group", :access=>"read"}),
                             Hydra::AccessControls::Permission.new({:name=>"frank.feng@york.ac.uk", :type=> "person", :access => "edit"})]
      fileset.depositor   = "frank.feng@york.ac.uk"
#fileset.thumbnail_path_service = CurationConcerns::ThumbnailPathService
      puts 'defined fileset'

      contentfile = open("/var/tmp/test.pdf")
      actor = CurationConcerns::Actors::FileSetActor.new(fileset, user)
      puts 'user_key' + user.user_key.to_s

      puts 'defined actor'
      actor.create_metadata(thesis)
      puts "created metadata"
      actor.create_content(contentfile, relation = 'original_file' )
      puts "created content"

#fileset.create_derivatives("/var/tmp/test.pdf")
#puts 'created derivatives'

      fileset.save!
      puts 'fileset saved!'

      thesis.members << fileset
      thesis.save!
      puts 'added fileset to thesis!'


    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

  end

end
