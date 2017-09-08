# Generated via
#  `rails generate curation_concerns:work JournalArticle`
module CurationConcerns
  class JournalArticleForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::JournalArticle

    #self.terms += [:year]
    self.terms += [:title, :creator_string, :journal_resource_ids, :issue_number, :volume_number, :pages, :rights
                   ]
    self.required_fields = [:title, :creator_string, :journal_resource_ids]
  end
end
