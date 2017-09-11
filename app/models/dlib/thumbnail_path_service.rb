module Dlib
  class ThumbnailPathService < CurationConcerns::ThumbnailPathService
    def self.logger
      logger = Logger.new('log/workflow.log', 0, 100 * 1024 * 1024)
    end

    class << self
      # @param [Work, FileSet] the object to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        if object.thumbnail_id.present?
          thumb = fetch_thumbnail(object)

          if thumb.present? && thumb.is_a?(::FileSet) && thumbnail?(thumb)
            thumbnail_path(thumb)
          else
            default_dlib_thumbnails(object)
          end
        else
          default_dlib_thumbnails(object)
        end
      end

      def default_dlib_thumbnails(obj)
        if obj.is_a? Collection
          collection_thumbnail
        elsif obj.is_a? Thesis
          thesis_thumbnail
        elsif obj.is_a? ExamPaper
          exam_paper_thumbnail
        elsif obj.is_a? JournalArticle
          journal_article_thumbnail
        else
          default_image
        end

      end

      def collection_thumbnail
        ActionController::Base.helpers.image_path 'default_thumbnails/collection.jpg'
      end

      def thesis_thumbnail
        ActionController::Base.helpers.image_path 'default_thumbnails/thesis.jpg'
      end

      def exam_paper_thumbnail
        ActionController::Base.helpers.image_path 'default_thumbnails/exampaper.jpg'
      end

      def journal_article_thumbnail
        ActionController::Base.helpers.image_path 'default_thumbnails/scholarlytext.jpg'
      end

    end
  end
end