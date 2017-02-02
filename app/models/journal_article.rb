# Generated via
#  `rails generate curation_concerns:work JournalArticle`
class JournalArticle < Dlibhydra::JournalArticle
  include ::CurationConcerns::WorkBehavior
  
  self.human_readable_type = 'Journal Article'
  validates :title, presence: { message: 'Your journal article must have a title.' }
  

  class JournalArticleIndexer < CurationConcerns::WorkIndexer
    include Dlibhydra::IndexesJournalArticle
  end

  def self.indexer
    JournalArticleIndexer
  end
end
