require 'spec_helper'

require_relative '../../app/workflow/exam_paper_processor.rb'

describe ExamPaperProcessor do

  describe 'ExamPaperProcessor' do
    it 'can ingest a new exam paper from json' do
      message = get_exam_paper_json()
      ExamPaperProcessor.process(message)
    end

    # it 'can attach files to an existing exam paper' do
    #   message = get_exam_paper_without_metadata_json()
    #   ExamPaperProcessor.process(message)
    # end
  end

  def get_exam_paper_json()
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
        "embedded_files": [
          {
            "title" : "",
            "path"  : "/var/tmp/test1.pdf",
            "mainfile": "true"
          },
          {
            "title" : "",
            "path"  : "/var/tmp/pdf.jpg",
            "mainfile": "false"
          },
          {
            "title" : "",
            "path"  : "/var/tmp/test2.jpg",
            "mainfile": "false"
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
          "title"                : ["exam_paper_title"],
          "creator"              : ["Frank Feng"],
          "date"                 : ["2017"],
          "qualification_level"  : ["Masters (Postgraduate)"],
          "qualification_name"   : ["1v53jw986"],
          "module_code"          : ["module_code_test"],
          "description "         : ["description  text here"],
          "language"             : ["eng","aar"],
          "rights_holder"        : ["UoY"],
          "rights"               : ["http://dlib.york.ac.uk/licences#yorkrestricted"],
          "visibility"           : "public",
          "former_id"            : ["york:XXXXX"]
        }
      }
  '
  end

  def get_exam_paper_without_metadata_json()
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
        "embedded_files": [
          {
            "title" : "",
            "path"  : "/var/tmp/test1.pdf",
            "mainfile": "true"
          },
          {
            "title" : "",
            "path"  : "/var/tmp/test2.jpg",
            "mainfile": "false"
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
        "id": "2f75r800t"
      }
  '
  end

end