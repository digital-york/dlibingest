
class BasicProcessor

  # define basic permission settings for objects
  def self.assign_permissions(user, permissions="public", object)
    # if user makes resource available to 'public'
    if permissions=='public' # open access
      object.permissions = [Hydra::AccessControls::Permission.new({:name     => "public",
                                                                   :type     => "group",
                                                                   :access   => "read"}),
                            Hydra::AccessControls::Permission.new({:name   => user.email, # Allow resource owner editing the resource
                                                                   :type   => "person",
                                                                   :access => "edit"})]
    elsif permissions=='york' # University of York only
      object.permissions = [Hydra::AccessControls::Permission.new({:name     => "york",
                                                                   :type     => "group",
                                                                   :access   => "read"}),
                            Hydra::AccessControls::Permission.new({:name   => user.email, # Allow resource owner editing the resource
                                                                   :type   => "person",
                                                                   :access => "edit"})]
    elsif permissions=='embargo' # embargo
      logger.error 'Not implemeted yet -> ' + permissions
      raise NotImplementedError
    elsif permissions=='lease'   # lease
      logger.error 'Not implemeted yet -> ' + permissions
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

  # define basic file processing logic, including embedded files and external urls
  def self.process_files(user, permissions, obj, embedded_files, external_files)

    # process all embedded files
    if embedded_files.present?
      embedded_files.each do |embedded_file|
        fileset = Dlibhydra::FileSet.new

        fileset.filetype = 'embeddedfile'

        #TODO: get title from upload page
        fileset.title = ['XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX']

        #define fileset permissions
        fileset = assign_permissions(user, permissions, fileset)

        #TODO: get filename
        filename = 'XXXX'
        contentfile = open(filename)
        actor = CurationConcerns::Actors::FileSetActor.new(fileset, user)

        #add metadata to make fileset appear as a child of the object
        actor.create_metadata(obj)
        actor.create_content(contentfile, relation = 'original_file' )

        fileset.save!
        puts 'fileset saved!'

        obj.members << fileset
        obj.save!
        puts 'added fileset to thesis!'
      end
    else
      logger.info 'No embedded file found.'
    end

    # process all external files
    if external_files.present?
      external_files.each do |external_file|
        fileset = Dlibhydra::FileSet.new

        fileset.filetype = 'externalurl'

        #TODO: get external url
        url = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

        fileset.external_file_url = url

        #TODO: get title from upload page
        fileset.title = ['XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX']

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

  end

  def self.get_embedded_files(message)
    #TODO: extract embedded files
    embedded_files = nil
  end

  def self.get_external_files(message)
    #TODO: extract external files
    external_files = nil
  end

end