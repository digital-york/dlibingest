class CollectionPresenter < CurationConcerns::CollectionPresenter

    # Metadata Methods
    delegate :rights_holder, :date, :former_id, to: :solr_document

  end