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

  # add local fields below, do not add those already used by curation concerns:
  #   title, creator, contributor, publisher, description, rights, subject
  #   unless our usage should override the existing field

  def abstract
    self[Solrizer.solr_name('abstract')]
  end

  def advisor
    self[Solrizer.solr_name('advisor')]
  end

  def awarding_institution
    self[Solrizer.solr_name('awarding_institution')]
  end

  def creator
    self[Solrizer.solr_name('creator_value')]
  end

  def date
    self[Solrizer.solr_name('date')]
  end

  def date_of_award
    self[Solrizer.solr_name('date_of_award')]
  end

  def department
    self[Solrizer.solr_name('department')]
  end

  def former_id
    self[Solrizer.solr_name('former_id')]
  end

  def keyword
    self[Solrizer.solr_name('keyword')]
  end

  def mainfile_ids
    self[Solrizer.solr_name('mainfile_ids')]
  end

  def module_code
    self[Solrizer.solr_name('module_code')]
  end

  def qualification_level
    self[Solrizer.solr_name('qualification_level')]
  end

  def qualification_name
    self[Solrizer.solr_name('qualification_name')]
  end

  def rights_holder
    self[Solrizer.solr_name('rights_holder')]
  end

  def subject
    self[Solrizer.solr_name('subject_value')]
  end

  # Do content negotiation for AF models. 

  use_extension(Hydra::ContentNegotiation)
end
