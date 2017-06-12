require 'json'
require 'hydra/works'
require 'logger'
require_relative 'basic_processor.rb'

class ThesisProcessor < BasicProcessor

  # process Thesis submission
  def self.process(message)
    logger.info 'Ingesting thesis to Fedora ...'
    logger.info '---------------message--------------'
    logger.info message.inspect
    logger.info '-----------------------------'

    begin
      # construct Thesis object from message received
      thesis = get_thesis(message)

      ##TODO: get userid from message
      userid = '1'
      user =  User.find(userid)

      ##TODO: get permissions setting from message
      permissions = 'public'  # currently, support 'public', 'york', 'embargo', 'lease', and 'private'

      ## define permissions for the thesis created
      assign_permissions(user, permissions, thesis)

      thesis.save!

      #process embedded files & external files
      process_files(user,
                    permissions,
                    thesis,
                    get_embedded_files(message),
                    get_external_files(message))

    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace
    end

  end

  # construct thesis object from text message
  def self.get_thesis(message)
    json_s = message.first.to_json
    json   = JSON.parse json_s

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
    qualification_name_array    = qualification_name.split(',')
    qualification_level_array   = qualification_level.split(',')
    awarding_institution_array  = awarding_institution.split(',')

    thesis = Dlibhydra::Thesis.create

    thesis.title                = title_array
    thesis.keyword              = keywords_array
    #thesis.keyword             = ['northern misery']
    thesis.rights               = rights
    thesis.language             = languages_array
    #thesis.language            = ['en-GB']
    thesis.department           = departments_array
    thesis.advisor              = advisors_array
    thesis.qualification_name   = qualification_name_array
    thesis.qualification_level  = qualification_level_array
    thesis.date_of_award        = date_of_award
    thesis.awarding_institution = awarding_institution_array

    thesis
  end

end