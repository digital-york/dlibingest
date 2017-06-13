require 'spec_helper'

require_relative '../../app/workflow/thesis_processor.rb'

describe ThesisProcessor do

  describe 'ThesisProcessor' do
    it 'has a processor' do
      expect 1==1
    end

    it 'has a method' do
      message = get_thesis_json()
      ThesisProcessor.process(message)
    end
  end

  def get_thesis_json()
    json = [
        'creator'              => 'creator_value',
        'keyword'              => 'keyword_value',
        'rights'               => 'rights_value',
        'subject'              => 'subject_value',
        'language'             => 'language_value',
        'visibility'           => 'visibility_value',
        'preflabel'            => 'preflabel_value',
        'abstract'             => 'abstract_value',
        'department'           => 'department_value',
        'qualification_name'   => 'qualification_name_value',
        'qualification_level'  => 'qualification_level_value',
        'date_of_award'        => 'date_of_award_value',
        'advisor'              => 'advisor_value',
        'awarding_institution' => 'awarding_institution_value'
    ]
  end

end