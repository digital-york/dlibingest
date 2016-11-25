# Generated via
#  `rails generate curation_concerns:work ExamPaper`

module CurationConcerns
  class ExamPapersController < ApplicationController
    include CurationConcerns::CurationConcernController
    self.curation_concern_type = ExamPaper
    def show_presenter
      ExamPaperShowPresenter
    end
  end
end
