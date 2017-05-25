class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include CurationConcerns::ThemedLayoutController
  with_themed_layout '1_column'


  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include CurationConcerns::ThemedLayoutController
  with_themed_layout '1_column'


  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include CurationConcerns::ThemedLayoutController
  with_themed_layout '1_column'


  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Adds CurationConcerns behaviors to the application controller.
  include CurationConcerns::ApplicationControllerBehavior
  include CurationConcerns::ThemedLayoutController
  with_themed_layout '1_column'


  protect_from_forgery with: :exception


  def render_thumbnail(document, options)
    return unless document[:file_id].present?
    url = thumbnail_url(document)

    image_tag url, image_options if url.present?
  end

end
