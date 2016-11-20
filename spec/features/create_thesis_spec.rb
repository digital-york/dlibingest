# Generated via
#  `rails generate curation_concerns:work Thesis`
require 'rails_helper'
include Warden::Test::Helpers

feature 'Create a Thesis' do
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
      visit new_curation_concerns_thesis_path
      fill_in 'Title', with: 'Test Thesis'
      click_button 'Create Thesis'
      expect(page).to have_content 'Test Thesis'
    end
  end
end
