module CurationConcerns
  class ThesisShowPresenter < CurationConcerns::WorkShowPresenter
    # Metadata Methods
    delegate :abstract, :advisor, :keyword, :qualification_level, :awarding_institution, :department,
             :qualification_name, :date_of_award, :former_id, :rights_holder,
             to: :solr_document
  end
end

