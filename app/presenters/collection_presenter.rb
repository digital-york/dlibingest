class CollectionPresenter < CurationConcerns::CollectionPresenter

    # Metadata Methods
    delegate :rights_holder, :date, :former_id, :creator_value, to: :solr_document

  end