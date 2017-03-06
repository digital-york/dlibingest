class IngestFileJob < ActiveJob::Base
  queue_as CurationConcerns.config.ingest_queue_name

  # File size threshold (in MB), bigger files will be sent to the workflow
  @@FILE_SIZE_THRESHOLD = 200

  def perform(file_set, filepath, user, opts = {})
    filesize  = '%.2f' % (File.size(filepath).to_f / 2**20)

    if filesize < @@FILE_SIZE_THRESHOLD
      # If file size is not too large, process file in the web application

      # Wrap in an IO decorator to attach passed-in options
      local_file = Hydra::Derivatives::IoDecorator.new(File.open(filepath, "rb"))
      local_file.mime_type = opts.fetch(:mime_type, nil)
      local_file.original_name = opts.fetch(:filename, File.basename(filepath))

      # Tell AddFileToFileSet service to skip versioning because versions will be minted by
      # VersionCommitter when necessary during save_characterize_and_record_committer.
      Hydra::Works::AddFileToFileSet.call(file_set,
                                          local_file,
                                          relation,
                                          versioning: false)

      # Persist changes to the file_set
      file_set.save!

      repository_file = file_set.send(relation)

      # Do post file ingest actions
      CurationConcerns::VersioningService.create(repository_file, user)

      # TODO: this is a problem, the file may not be available at this path on another machine.
      # It may be local, or it may be in s3
      CharacterizeJob.perform_later(file_set, repository_file.id, filepath)
    else
      # Send file to backend workflow for processing

    end
  end

  # generate file information json before sending to workflow workers
  def file_info_json(file_set, filepath, user, opts)
    filesize  = '%.2f' % (File.size(filepath).to_f / 2**20)
    mime      = opts.fetch(:mime_type, :original_file).to_sym
    filename  = opts.fetch(:filename,  :original_file).to_sym
    relation  = opts.fetch(:relation,  :original_file).to_sym

    file_info_json = {
        'files' => [
            {
                'fullpath' => filepath,
                'filename' => filename,
                'filesize' => filesize,
                'mimetype' => mime,
                'relation' => relation
            }
        ],
        'fileset' => {
            'id'    => file_set.id,
            'title' => file_set.title
        },
        'user' => {
            'id'    => user.id,
            'email' => user.email,
            'guest' => user.guest
        }
    }
  end
end
