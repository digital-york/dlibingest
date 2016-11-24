# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  # Adds CurationConcerns behaviors to the SolrDocument.
  include CurationConcerns::SolrDocumentBehavior


  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # trying to solve show/item display problem
  def abstract
    self[Solrizer.solr_name('abstract')]
  end

  def advisor
    self[Solrizer.solr_name('advisor')]
  end

  #added 17th nov for SHOW page
  def keyword
    self[Solrizer.solr_name('keyword')]
  end

  def qualification_level
    self[Solrizer.solr_name('qualification_level')]
  end

  def qualification_name
    self[Solrizer.solr_name('qualification_name')]
  end

  def date_of_award
    self[Solrizer.solr_name('date_of_award')]
  end

  def awarding_institution
    self[Solrizer.solr_name('awarding_institution')]
  end

  def department
    self[Solrizer.solr_name('department')]
  end

  def date
    self[Solrizer.solr_name('date')]
  end

  def rights_holder
    self[Solrizer.solr_name('rights_holder')]
  end

  #maybe this is needed...not sure
  def subject
    self[Solrizer.solr_name('subject_value')]
  end

  #CHOSS
  #maybe this is needed...not sure
=begin
def subject
  self[Solrizer.solr_name('subject')]
end
=end

  def rights_holder
    self[Solrizer.solr_name('rights_holder')]
  end

  # not needed - already in cc
  # new addition 12th sept
  # def rights
  #   self[Solrizer.solr_name('rights')]
  # end

  # not needed - not currently using
  # new addition 1st sept
  # def preflabel
  #   self[Solrizer.solr_name('preflabel')]
  # end

  # new addition 26th sept
  def former_id
    self[Solrizer.solr_name('former_id')]
  end

  # new addition 26th sept
  def mainfile_ids
    self[Solrizer.solr_name('mainfile_ids')]
  end

  # Do content negotiation for AF models. 

  use_extension(Hydra::ContentNegotiation)
end
