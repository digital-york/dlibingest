class CollectionEditForm < CurationConcerns::CollectionEditForm

  self.terms += [:date, :subject_resource_ids, :creator_resource_ids, :publisher_resource_ids, :rights_holder]

  self.required_fields = [:title, :description, :creator_resource_ids]

end