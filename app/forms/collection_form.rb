class CollectionForm < CurationConcerns::Forms::CollectionEditForm

  self.terms += [:date, :subject_resource_ids, :creator_resource_ids, :publisher_resource_ids, :rights_holder, :former_id]

  self.required_fields = [:title, :description]

end