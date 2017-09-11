# Generated via
#  `rails generate curation_concerns:work ExamPaper`
class ExamPaper < Dlibhydra::ExamPaper
  include ::CurationConcerns::WorkBehavior

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  self.human_readable_type = 'Exam Paper'
  validates :title, presence: { message: 'Your work must have a title.' }

  class ExamPaperIndexer < CurationConcerns::WorkIndexer
    include Dlibhydra::IndexesExamPaper

    self.thumbnail_path_service = Dlib::ThumbnailPathService
  end

  def self.indexer
    ExamPaperIndexer
  end
end
