module CurationConcerns
  class ExamPaperShowPresenter < CurationConcerns::WorkShowPresenter

    # Additional Metadata Methods
    # title, creator, rights, language, description, subject are already included
    delegate :qualification_level, :qualification_name,  :keyword, :date, :former_id, :rights_holder,
             :module_code, :creator_value, 
             to: :solr_document

  end
end

