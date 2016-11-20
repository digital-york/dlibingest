# Generated via
#  `rails generate curation_concerns:work Thesis`

module CurationConcerns
  class ThesesController < ApplicationController
    include CurationConcerns::CurationConcernController
    self.curation_concern_type = Thesis
  end
end
