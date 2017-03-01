# Generated via
#  `rails generate curation_concerns:work JournalArticle`
module CurationConcerns
  class JournalArticleForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::JournalArticle

    self.terms += [:date]

    self.required_fields = [:title, :creator_string, :journal_resource_ids, :date]
  end
end
