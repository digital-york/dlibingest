class CatalogController < ApplicationController
  include CurationConcerns::CatalogController

  configure_blacklight do |config|
    # config.search_builder_class = ::SearchBuilder
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
        qf: %w(title_tesim name_tesim),
        qt: 'search',
        rows: 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title', :stored_searchable)
    config.index.display_type_field = solr_name('has_model', :symbol)

    # new fields - are these needed?
    config.index.creator_field = solr_name('creator_value', :stored_searchable)
    #config.index.creator_field = solr_name('creator', :stored_searchable)#added 12 august
    config.index.advisor_field = solr_name('advisor', :stored_searchable)#added 12 august
    config.index.date_of_award_field = solr_name('date', :stored_searchable)
    config.index.date_of_award_field = solr_name('date_of_award', :stored_searchable)#added 12 august
    config.index.abstract_field = solr_name('abstract', :stored_searchable)#added 12 august
    config.index.rights_holder_field = solr_name('rights_holder', :stored_searchable)#added 13 august
    config.index.former_id_field = solr_name('former_id', :stored_searchable)#added 25 oct new dlibhydra models
    config.index.module_code_field = solr_name('module_code', :stored_searchable)
    config.index.mainfile_ids_field = solr_name('mainfile_ids', :stored_searchable)#added 25 oct new dlibhydra models
    # end of new fields

    config.index.thumbnail_field = 'thumbnail_path_ss'
    config.index.partials.delete(:thumbnail) # we render this inside _index_default.html.erb
    config.index.partials += [:action_menu]

    # solr field configuration for document/show views
    # config.show.title_field = solr_name("title", :stored_searchable)
    # config.show.display_type_field = solr_name("has_model", :symbol)

    # To define customized view



    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name('human_readable_type', :facetable), limit: 5
    config.add_facet_field solr_name('creator_value', :facetable), limit: 5
    config.add_facet_field solr_name('advisor_value', :facetable), limit: 5
    config.add_facet_field solr_name('department_value', :facetable)
    config.add_facet_field solr_name('publisher', :facetable)
    # TODO date facets will need work
    config.add_facet_field solr_name('date_of_award', :facetable)
    config.add_facet_field solr_name('date', :facetable)
    config.add_facet_field solr_name('keyword', :facetable), limit: 5
    config.add_facet_field solr_name('subject_value', :facetable), limit: 5
    config.add_facet_field solr_name('language_string', :facetable), limit: 5
    config.add_facet_field solr_name('qualification_level', :facetable)
    config.add_facet_field solr_name('qualification_name_value', :facetable)

    config.add_facet_field 'generic_type_sim', show: false, single: true
    # config.add_facet_field solr_name('based_near', :facetable), limit: 5
    # config.add_facet_field solr_name('publisher', :facetable), limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
	
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name('creator_value', :stored_searchable)
    #config.add_index_field solr_name('creator', :stored_searchable)
    config.add_index_field solr_name('advisor_value', :stored_searchable)
    config.add_index_field solr_name('date', :stored_searchable)
    config.add_index_field solr_name('date_of_award', :stored_searchable)
    config.add_index_field solr_name('department_value', :stored_searchable)
    config.add_index_field solr_name('publisher', :stored_searchable)
    config.add_index_field solr_name('qualification_name_value', :stored_searchable)
    config.add_index_field solr_name('qualification_level', :stored_searchable)
    config.add_index_field solr_name('awarding_institution_value', :stored_searchable)
    config.add_index_field solr_name('language', :stored_searchable)
    config.add_index_field solr_name('language_string', :stored_searchable)
    config.add_index_field solr_name('keyword', :stored_searchable)
    config.add_index_field solr_name('subject_value', :stored_searchable)
    config.add_index_field solr_name('module_code', :stored_searchable)
    config.add_index_field solr_name('rights', :stored_searchable)
    config.add_index_field solr_name('human_readable_type', :stored_searchable)


    # not used in results display
    # config.add_index_field solr_name('rights_holder', :stored_searchable)
    # config.add_index_field solr_name('description', :stored_searchable)
    # config.add_index_field solr_name('abstract', :stored_searchable)
    # config.add_index_field solr_name('mainfile_ids', :stored_searchable)
    # config.add_index_field solr_name('former_id', :stored_searchable)

    # config.add_index_field solr_name('contributor', :stored_searchable)
    # config.add_index_field solr_name('based_near', :stored_searchable)
    # config.add_index_field solr_name('date_uploaded', :stored_sortable)
    # config.add_index_field solr_name('date_modified', :stored_sortable)
    # config.add_index_field solr_name('date_created', :stored_searchable)
    # config.add_index_field solr_name('format', :stored_searchable)
    # config.add_index_field solr_name('identifier', :stored_searchable)


    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: false) do |field|
      title_name = solr_name('title', :stored_searchable, type: :string)
      label_name = solr_name('title', :stored_searchable, type: :string)
      contributor_name = solr_name('contributor', :stored_searchable, type: :string)
      field.solr_parameters = {
          qf: "#{title_name} #{label_name} #{contributor_name}",
          pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,

    # solr_parameters hash are sent to Solr as ordinary url query params.

    # :solr_local_parameters will be sent using Solr LocalParams
    # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    # Solr parameter de-referencing like $title_qf.
    # See: http://wiki.apache.org/solr/LocalParams

    config.add_search_field('creator') do |field|
      solr_name = solr_name('creator_value', :stored_searchable, type: :string)
      #solr_name = solr_name('creator_value', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      solr_name = solr_name('title', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = 'Abstract or Summary'
      solr_name = solr_name('description', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      solr_name = solr_name('publisher_value', :stored_searchable, type: :string)
      #solr_name = solr_name('publisher', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      solr_name = solr_name('created', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      #solr_name = solr_name('subject', :stored_searchable, type: :string)   #CHOSS
      solr_name = solr_name('subject_value', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      solr_name = solr_name('language', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end
    config.add_search_field('language_string') do |field|
      solr_name = solr_name('language_string', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('human_readable_type') do |field|
      solr_name = solr_name('human_readable_type', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    # config.add_search_field('format') do |field|
    #   field.include_in_advanced_search = false
    #   solr_name = solr_name('format', :stored_searchable, type: :string)
    #   field.solr_local_parameters = {
    #     qf: solr_name,
    #     pf: solr_name
    #   }
    # end

    config.add_search_field('identifier') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name('id', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    # config.add_search_field('based_near') do |field|
    #   field.label = 'Location'
    #   solr_name = solr_name('based_near', :stored_searchable, type: :string)
    #   field.solr_local_parameters = {
    #     qf: solr_name,
    #     pf: solr_name
    #   }
    # end

    config.add_search_field('keyword') do |field|
      solr_name = solr_name('keyword', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = solr_name('depositor', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('rights_holder') do |field|
      solr_name = solr_name('rights_holder', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('rights') do |field|
      solr_name = solr_name('rights', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    # local ones

    config.add_search_field('department') do |field|
      solr_name = solr_name('department', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('advisor') do |field|
      solr_name = solr_name('advisor_value', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('awarding_institution') do |field|
      solr_name = solr_name('awarding_institution_value', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('qualification_level') do |field|
      solr_name = solr_name('qualification_level', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('qualification_name') do |field|
      solr_name = solr_name('qualification_name_value', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('former_id') do |field|
      solr_name = solr_name('former_id', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('module_code') do |field|
      solr_name = solr_name('module_code', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    # new 24 oct new dlibhydra models
    config.add_search_field('mainfile_ids') do |field|
      solr_name = solr_name('mainfile_ids', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance \u25BC"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end
end
