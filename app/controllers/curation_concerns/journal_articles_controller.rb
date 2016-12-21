# Generated via
#  `rails generate curation_concerns:work JournalArticle`

module CurationConcerns
  class JournalArticlesController < ApplicationController
    include CurationConcerns::CurationConcernController
    self.curation_concern_type = JournalArticle
  end
end
