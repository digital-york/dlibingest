require 'json'
require 'hydra/works'
require 'logger'
require 'dlibhydra'

require_relative 'basic_processor.rb'

class ExamPaperProcessor < BasicProcessor

  # process ExamPaper submission
  def self.process(message)

    begin
      # construct ExamPaper object from message received
      exam_paper = get_exam_paper(message)

      userid = get_userid(message)
      user =  User.find(userid)

      permission = get_permission(message)  # currently, support 'public', 'york', 'embargo', 'lease', and 'private'

      ## define permissions for the thesis created
      assign_permissions(user, permission, exam_paper)

      exam_paper.save!
      logger.info 'Exam paper saved. id: ' + exam_paper.id

      #process embedded files & external files
      process_files(user,
                    permission,
                    exam_paper,
                    get_embedded_files(message),
                    get_external_files(message))

    rescue Exception => e
      self.logger.error e.message
      self.logger.error e.backtrace
    end

  end

  # construct exam paper object from json/text message
  def self.get_exam_paper(message)
    json = JSON.parse(message)

    id = json['id']

    if id.present?
      t = ExamPaper.find(id)
      if t.present?
        self.logger.info 'Found exam paper: ' + id
        return t
      else
        self.logger.warn 'Cannot find exam paper with id: ' + id
      end
    else
      logger.info 'No exam paper object id provided, creating object now. '
    end

    titles                = json['metadata']["title"]
    creators              = json['metadata']['creator']
    date                  = json['metadata']["date"]
    qualification_levels  = json['metadata']["qualification_level"]
    qualification_names   = json['metadata']["qualification_name"]
    module_codes          = json['metadata']['module_code']
    description           = json['metadata']["description"]
    languages             = json['metadata']["language"]
    rights_holders        = json['metadata']["rights_holder"]
    rights                = json['metadata']["rights"]

    visibility            = json['metadata']["visibility"]

    former_ids            = json['metadata']["former_id"]

    exam_paper = ExamPaper.create

    exam_paper.date_uploaded                   = Time.now
    exam_paper.date_modified                   = Time.now

    exam_paper.title                           = titles
    exam_paper.preflabel                       = titles[0]
    exam_paper.creator_string                  = creators
    exam_paper.date                            = date
    exam_paper.qualification_level             = qualification_levels
    exam_paper.qualification_name_resource_ids = qualification_names
    exam_paper.module_code                     = module_codes
    exam_paper.description                     = description
    exam_paper.language                        = languages
    exam_paper.rights_holder                   = rights_holders
    exam_paper.rights                          = rights
    exam_paper.former_id                       = former_ids

    exam_paper
  end

end