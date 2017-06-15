require 'json'
require 'hydra/works'
require 'logger'
require 'dlibhydra'

require_relative 'basic_processor.rb'

class ThesisProcessor < BasicProcessor

  # process Thesis submission
  def self.process(message)

    begin
      # construct Thesis object from message received
      thesis = get_thesis(message)

      userid = get_userid(message)
      user =  User.find(userid)

      permission = get_permission(message)  # currently, support 'public', 'york', 'embargo', 'lease', and 'private'

      ## define permissions for the thesis created
      assign_permissions(user, permission, thesis)

      thesis.save!
      logger.info 'Thesis saved. id: ' + thesis.id

      #process embedded files & external files
      process_files(user,
                    permission,
                    thesis,
                    get_embedded_files(message),
                    get_external_files(message))

    rescue Exception => e
      self.logger.error e.message
      self.logger.error e.backtrace
    end

  end

  # construct thesis object from json/text message
  def self.get_thesis(message)
    json = JSON.parse(message)

    creators              = json['metadata']['creator']
    keywords              = json['metadata']['keyword']
    rights                = json['metadata']["rights"]
    subjects              = json['metadata']["subject"]
    languages             = json['metadata']["language"]
    departmentids         = json['metadata']["department"]
    advisors              = json['metadata']["advisor"]
    visibility            = json['metadata']["visibility"]
    titles                = json['metadata']["title"]
    abstracts             = json['metadata']["abstract"]
    qualification_names   = json['metadata']["qualification_name"]
    qualification_levels  = json['metadata']["qualification_level"]
    date_of_award         = json['metadata']["date_of_award"]
    awarding_institutions = json['metadata']["awarding_institution"]
    former_ids            = json['metadata']["former_id"]
    dois                  = json['metadata']["doi"]

    #thesis = Dlibhydra::Thesis.create
    thesis = Thesis.create

    thesis.date_uploaded           = Time.now
    thesis.date_modified           = Time.now

    thesis.title                   = titles
    thesis.preflabel               = titles[0]
    thesis.creator_string          = creators
    thesis.advisor_string          = advisors
    thesis.abstract                = abstracts
    thesis.keyword                 = keywords
    thesis.rights                  = rights
    thesis.language                = languages
    thesis.department_resource_ids = departmentids
    thesis.subject_resource_ids    = subjects
    thesis.qualification_name_resource_ids  = qualification_names
    thesis.qualification_level              = qualification_levels
    thesis.date_of_award                     = date_of_award
    thesis.awarding_institution_resource_ids = awarding_institutions
    thesis.former_id                         = former_ids
    thesis.doi                               = dois

    thesis
  end

end