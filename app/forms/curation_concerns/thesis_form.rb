# Generated via
#  `rails generate curation_concerns:work Thesis`
module CurationConcerns
  class ThesisForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::Thesis

    # add to those already defined in curation_concerns/app/forms/curation_concerns/forms/work_form.rb
    # use the _ids form for HABM
    # TODO advisor
    self.terms += [:abstract, :department_resource_ids, :qualification_name_resource_ids, :qualification_level,
                   :date_of_award, :advisor, :keyword, :awarding_institution_resource_ids,
                   :rights_holder, :subject_resource_ids, :creator_string, :creator_resource_id, :advisor_resource_id]

    self.required_fields = [:title, :department_resource_ids, :date_of_award]
  end
end