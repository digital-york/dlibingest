module CurationConcerns
  class ThesisShowPresenter < CurationConcerns::WorkShowPresenter

    # Additional Metadata Methods
    # title, creator, rights, language are already included
    delegate :abstract, :advisor, :keyword, :qualification_level, :awarding_institution, :department,
             :qualification_name, :date_of_award, :former_id, :rights_holder, :creator_value, :language_string,
             to: :solr_document

  end
end

