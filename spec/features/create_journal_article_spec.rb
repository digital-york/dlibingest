# Generated via
#  `rails generate curation_concerns:work JournalArticle`
require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Create a JournalArticle' do
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
      visit new_curation_concerns_journal_article_path
      fill_in 'Title', with: 'Test JournalArticle'
      click_button 'Create JournalArticle'
      expect(page).to have_content 'Test JournalArticle'
    end
  end
end
