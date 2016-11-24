module CurationConcerns
  class CollectionShowPresenter

    # Metadata Methods
    delegate :rights_holder, :date, to: :solr_document

  end
end