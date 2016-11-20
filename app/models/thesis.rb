# Generated via
#  `rails generate curation_concerns:work Thesis`
class Thesis < Dlibhydra::Thesis
  # include ::CurationConcerns::NestedWork
  include ::CurationConcerns::WorkBehavior
  # include ::CurationConcerns::BasicMetadata

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  self.human_readable_type = 'Thesis'
  validates :title, presence: { message: 'Your work must have a title.' }

  class ThesisIndexer < CurationConcerns::WorkIndexer # Hydra::PCDM::PCDMIndexer
    include Dlibhydra::IndexesThesis
  end

  def self.indexer
    ThesisIndexer
  end

end
