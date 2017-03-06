class IngestFileJob < ActiveJob::Base
  queue_as CurationConcerns.config.ingest_queue_name

  # File size threshold (in MB), bigger files will be sent to the workflow
  @@FILE_SIZE_THRESHOLD = 200

  def perform(file_set, filepath, user, opts = {})

    filesize = '%.2f' % (File.size(filepath).to_f / 2**20)
    relation = opts.fetch(:relation, :original_file).to_sym

    puts '===================IngestFileJob.perform======================'
    puts filepath
    puts filesize
    puts file_set.inspect
    puts user.inspect
    puts opts.inspect
    puts relation
=begin
    # OUTPUT
    ====================================================================
    /home/frank/dlibingest/tmp/uploads/jq/08/5j/96/jq085j963/redis2.jpg
    0.07
    Load LDP (32.0ms) http://127.0.0.1:8080/fedora/rest/dev/a8/59/01/9c/a859019c-289b-4a0b-8c54-b9e58818fe12 Service: 70171117949960
#<FileSet id: "dr26xx39d", former_id: [], title: ["redis2.jpg"], rdfs_label: nil, preflabel: nil, altlabel: [], label: "redis2.jpg", relative_path: nil, import_url: nil, part_of: [], resource_type: [], creator: ["frank.feng@york.ac.uk"], contributor: [], description: [], keyword: [], rights: [], rights_statement: [], publisher: [], date_created: [], subject: [], language: [], identifier: [], based_near: [], related_url: [], bibliographic_citation: [], source: [], head: [], tail: [], depositor: "frank.feng@york.ac.uk", date_uploaded: "2017-03-05 18:29:36", date_modified: "2017-03-05 18:29:36", access_control_id: "eed3a7c8-a9aa-4fef-855c-fe2dfb7c2475", embargo_id: nil, lease_id: nil>
#<User id: 1, email: "frank.feng@york.ac.uk", guest: false>
    {:mime_type=>"image/jpeg", :filename=>"redis2.jpg", :relation=>"original_file"}
    original_file
    ====================================================================
=end
    puts '===================IngestFileJob.perform======================'
    file_info_json = {
        :fullpath => filepath,
        :filesize => filesize,

    }



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
  end

  # generate file information json before sending to workflow workers
  def fileinfo(file_set, filepath, user, opts)

  end
end
