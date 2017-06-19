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
        "permission" : "private",
        "embedded_files": [
          {
            "title" : "",
            "path"  : "/var/tmp/test1.pdf"
          },
          {
            "title" : "",
            "path"  : "/var/tmp/test2.jpg"
          }
        ],
        "external_files": [
          {
            "title" : "",
            "url"  : "https://www.york.ac.uk/static/data/homepage/images/foi-homepage-banner-alt.jpg"
          },
          {
            "title" : "",
            "url"  : "https://www.york.ac.uk/media/news-and-events/pressreleases/2017/hand-axe-505.jpg"
          }
        ],
        "metadata": {
          "title"                : ["title_1","title_2"],
          "creator"              : ["Frank Feng"],
          "date_of_award"        : "2017",
          "department"           : ["th83kz323"],
          "advisor"              : ["advisor_1","advisor_1"],
          "qualification_level"  : ["Masters (Postgraduate)"],
          "qualification_name"   : ["1v53jw986"],
          "abstract"             : ["abstract text here"],
          "keyword"              : ["keyword_1","keyword_2"],
          "language"             : ["eng","aar"],
          "rights_holder"        : "UoY",
          "awarding_institution" : "79407x16z",
          "rights"               : ["http://dlib.york.ac.uk/licences#yorkrestricted"],
          "subject"              : ["mp48sc77c"],
          "visibility"           : "visibility_value",
          "doi"                  : ["doi_1","doi_2"],
          "former_id"            : ["york:XXXXX"]
        }
      }
  '
  end

end