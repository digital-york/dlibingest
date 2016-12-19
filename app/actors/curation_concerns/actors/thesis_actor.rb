# Generated via
#  `rails generate curation_concerns:work Thesis`

require 'resque'
require 'json'
require_relative 'workflow_worker'

module CurationConcerns
  module Actors
    class ThesisActor < CurationConcerns::Actors::BaseActor

      def create(attributes)
          @cloud_resources = attributes.delete(:cloud_resources.to_s)
          apply_creation_data_to_curation_concern
          apply_save_data_to_curation_concern(attributes)

          thesis_json = get_thesis_json(attributes)
          Resque.enqueue(WorkflowWorker, thesis_json)
puts '===============Sending message to dlibmessage==============='
puts Resque.redis          

          # next_actor.create(attributes) && save && run_callbacks(:after_create_concern)
          save && next_actor.create(attributes) && run_callbacks(:after_create_concern)
      end

    private
      def get_thesis_json(attributes)
        creator              = attributes['creator']
        keyword              = attributes['keyword']
        rights               = attributes['rights']
        subject              = attributes['subject']
        language             = attributes['language']
        visibility           = attributes['visibility']
        preflabel            = attributes['preflabel']
        abstract             = attributes['abstract']
        department           = attributes['department']
        qualification_name    = attributes['qualification_name']
        qualification_level   = attributes['qualification_level']
        date_of_award        = attributes['date_of_award']
        advisor              = attributes['advisor']
        awarding_institution = attributes['awarding_institution']

        json = [
              'creator' => creator,
              'keyword' => keyword,
              'rights'  => rights,
              'subject' => subject,
              'language' => language,
              'visibility' => visibility,
              'preflabel' => preflabel,
              'abstract' => abstract,
              'department' => department,
              'qualification_name' => qualification_name,
              'qualification_level' => qualification_level,
              'date_of_award' => date_of_award,
              'advisor' => advisor,
              'awarding_institution' => awarding_institution
             ]        
     end  
  end
end
end
