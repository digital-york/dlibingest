
class BasicProcessor

  FILE_TYPE_EMBEDDED = 'embeddedfile'.freeze
  FILE_TYPE_EXTERNAL = 'externalurl'.freeze

  def self.logger
    # Start the log over whenever the log exceeds 100 megabytes in size.
    logger = Logger.new('log/workflow.log', 0, 100 * 1024 * 1024)
  end

  # define basic permission settings for objects
  def self.assign_permissions(user, permission="public", object)
    # if user makes resource available to 'public'
    if permission=='public' # open access
      object.permissions = [Hydra::AccessControls::Permission.new({:name     => "public",
                                                                   :type     => "group",
                                                                   :access   => "read"}),
                            Hydra::AccessControls::Permission.new({:name   => user.email, # Allow resource owner editing the resource
                                                                   :type   => "person",
                                                                   :access => "edit"})]
    elsif permission=='york' # University of York only
      object.permissions = [Hydra::AccessControls::Permission.new({:name     => "york",
                                                                   :type     => "group",
                                                                   :access   => "read"}),
                            Hydra::AccessControls::Permission.new({:name   => user.email, # Allow resource owner editing the resource
                                                                   :type   => "person",
                                                                   :access => "edit"})]
    elsif permission=='embargo' # embargo
      self.logger.error 'Not implemeted yet -> ' + permissions
      raise NotImplementedError
    elsif permission=='lease'   # lease
      self.logger.error 'Not implemeted yet -> ' + permissions
      raise NotImplementedError
    else # private
      # Allow resource owner editing the resource
      object.permissions = [
          Hydra::AccessControls::Permission.new({:name   => user.email,
                                                 :type   => "person",
                                                 :access => "edit"})]
    end

    object.depositor   = user.email

    object
  end

  def self.get_userid(message)
    json   = JSON.parse(message)
    userid = json['auth']['userid']
  end

  def self.get_permission(message)
    json        = JSON.parse(message)
    permission = json['permission']
  end

  # define basic file processing logic, including embedded files and external urls
  def self.process_files(user, permissions, obj, embedded_files, external_files)

    # process all embedded files
    if embedded_files.present?
      for i in 0..embedded_files.length-1
        filetitle = embedded_files[i]["title"]
        filename  = embedded_files[i]["path"]
        mainfile  = embedded_files[i]["mainfile"]
        fileset   = FileSet.new
        fileset.filetype = FILE_TYPE_EMBEDDED
        fileset.title    = filetitle
        #define fileset permissions
        fileset = assign_permissions(user, permissions, fileset)
        contentfile = open(filename)
        actor = CurationConcerns::Actors::FileSetActor.new(fileset, user)
        #add metadata to make fileset appear as a child of the object
        actor.create_metadata(obj)
        actor.create_content(contentfile, relation = 'original_file' )
        fileset.save!
        logger.info 'fileset saved!'

        obj.members << fileset

        if mainfile.present? && mainfile=='true'
          obj.mainfile << fileset
        end

        obj.save!
        logger.info 'added fileset to object: ' + fileset.id + ' -> ' + obj.id
      end
    else
      logger.info 'No embedded file found.'
    end

    # process all external files
    if external_files.present?
      for i in 0..external_files.length-1
        title = external_files[i]["title"]
        url   = external_files[i]["url"]

        #fileset = Dlibhydra::FileSet.new
        fileset = FileSet.new
        fileset.filetype          = FILE_TYPE_EXTERNAL
        fileset.external_file_url = url
        fileset.title             = title

        #define fileset permissions
        fileset = assign_permissions(user, permissions, fileset)

        #add metadata to make fileset appear as a child of the object
        actor = CurationConcerns::Actors::FileSetActor.new(fileset, user)
        actor.create_metadata(obj)

        #Decalre file as external resource
        Hydra::Works::AddExternalFileToFileSet.call(fileset, url, 'external_url')
        fileset.save!

        obj.members << fileset
        obj.save!
      end
    else
      logger.info 'No external file found.'
    end

=begin


=end
  end

  def self.get_embedded_files(message)
    json           = JSON.parse(message)
    embedded_files = json['embedded_files']
  end

  def self.get_external_files(message)
    json           = JSON.parse(message)
    embedded_files = json['external_files']
  end

end