# Generated via
#  `rails generate curation_concerns:work JournalArticle`
class JournalArticle < Dlibhydra::JournalArticle

  include ::CurationConcerns::WorkBehavior
  # include ::CurationConcerns::BasicMetadata
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  self.human_readable_type = 'Journal Article'
  validates :title, presence: { message: 'Your journal article must have a title.' }
  validates :journal_resource_ids, presence: { message: 'Your journal article must have a journal.' }

  class JournalArticleIndexer < CurationConcerns::WorkIndexer
    include Dlibhydra::IndexesJournalArticle
  end

  def self.indexer
    JournalArticleIndexer
  end

end
