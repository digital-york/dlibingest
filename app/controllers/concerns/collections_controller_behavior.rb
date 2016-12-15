module CollectionsControllerBehavior
  extend ActiveSupport::Concern
  include CurationConcerns::CollectionsControllerBehavior

  included do
    self.presenter_class = ::CollectionPresenter
    self.form_class = ::CollectionForm
  end

end