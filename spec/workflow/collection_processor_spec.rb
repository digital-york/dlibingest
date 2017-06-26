require 'spec_helper'

require_relative '../../app/workflow/collection_processor.rb'

describe CollectionProcessor do

  describe 'CollectionProcessor' do

    it 'can ingest a new collection from json' do
       message = get_collection_json()
       CollectionProcessor.process(message)
    end

  end

  def get_collection_json()
    json = '
      {
        "auth": {
          "userid"  : "1",
          "useremail": "frank.feng@york.ac.uk",
          "roles": [
            "public",
            "admin"
          ]
        },
        "permission" : "public",
        "metadata": {
          "title"                : ["collection_title"],
          "creator"              : ["Frank Feng"],
          "keyword"              : ["collection_keyword_1","collection_keyword_2"],
          "language"             : ["eng"],
          "rights"               : ["http://dlib.york.ac.uk/licences#yorkrestricted"],
          "rights_holder"        : ["UoY"],
          "subject"              : ["mp48sc77c"],
          "visibility"           : "visibility_value",
          "description"          : ["description text"],
          "former_id"            : ["york:XXXXX"]
        }
      }
  '
  end


end