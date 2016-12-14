# Generated via
#  `rails generate curation_concerns:work ExamPaper`
require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Create a ExamPaper' do
  context 'a logged in user' do
    let(:user_attributes) do
      { email: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end

    before do
      login_as user
    end

    scenario do
      visit new_curation_concerns_exam_paper_path
      fill_in 'Title', with: 'Test ExamPaper'
      click_button 'Create ExamPaper'
      expect(page).to have_content 'Test ExamPaper'
    end
  end
end
