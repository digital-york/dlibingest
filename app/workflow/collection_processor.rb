require 'json'
require 'hydra/works'
require 'logger'
require 'dlibhydra'

require_relative 'basic_processor.rb'

class CollectionProcessor < BasicProcessor

  # process Collection submission
  def self.process(message)

    begin
      # construct Thesis object from message received
      collection = get_collection(message)

      userid = get_userid(message)
      user   =  User.find(userid)

      permission = get_permission(message)

      ## define permissions for the collection created
      assign_permissions(user, permission, collection)

      collection.save!
      logger.info 'Collection saved. id: ' + collection.id

      #process embedded files & external files
      process_files(user,
                    permission,
                    collection,
                    get_embedded_files(message),
                    get_external_files(message))

    rescue Exception => e
      self.logger.error e.message
      self.logger.error e.backtrace
    end

  end

  # construct thesis object from json/text message
  def self.get_collection(message)
    json = JSON.parse(message)

    id = json['id']

    if id.present?
      c = Collection.find(id)
      if c.present?
        self.logger.info 'Found collection: ' + id
        return c
      else
        self.logger.warn 'Cannot find collection with id: ' + id + ', creating object now.'
      end
    else
      logger.info 'No collection object id provided, creating object now. '
    end

    creators              = json['metadata']['creator']
    keywords              = json['metadata']['keyword']
    rights                = json['metadata']["rights"]
    rights_holder         = json['metadata']["rights_holder"]
    subjects              = json['metadata']["subject"]
    languages             = json['metadata']["language"]
    visibility            = json['metadata']["visibility"]
    titles                = json['metadata']["title"]
    publisher             = json['metadata']["publisher"]
    date                  = json['metadata']["date"]
    description           = json['metadata']["description"]
    former_ids            = json['metadata']["former_id"]

    col = Collection.create

    col.date_uploaded           = Time.now
    col.date_modified           = Time.now

    col.title                   = titles
    col.preflabel               = titles[0]
    col.creator_string          = creators
    col.keyword                 = keywords
    col.rights                  = rights
    col.rights_holder           = rights_holder
    col.language                = languages
    col.subject_resource_ids    = subjects
    col.publisher_resource_ids  = publisher
    col.descripton              = description

    col.former_id               = former_ids

    col
  end

end