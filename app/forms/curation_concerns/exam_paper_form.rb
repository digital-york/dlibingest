# Generated via
#  `rails generate curation_concerns:work ExamPaper`
module CurationConcerns
  class ExamPaperForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::ExamPaper

    self.terms += [:qualification_name_resource_ids, :qualification_level, :module_code,
                   :date, :rights_holder, :creator_resource_ids, :creator_value]

    self.required_fields = [:title, :creator_resource_ids, :date]
  end
end
