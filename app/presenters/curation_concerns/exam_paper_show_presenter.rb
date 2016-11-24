module CurationConcerns
  class ExamPaperShowPresenter < CurationConcerns::WorkShowPresenter

    # Additional Metadata Methods
    # title, creator, rights, language, description, subject are already included
    delegate :qualification_level, :qualification_name, :date, :former_id, :rights_holder, :module_code,
             to: :solr_document
  end
end

