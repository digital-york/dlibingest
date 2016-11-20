module CurationConcernsHelper
  include ::BlacklightHelper
  include CurationConcerns::MainAppHelpers
  # TODO remove once fixed in CC
  # On creating 'new' items, an orphan Hydra::AccessControl container is created.
  # Destroy and remove completely from fedora.
  def access_control_cleanup(new_resource)
    unless new_resource.access_control_id.nil?
      ac = Hydra::AccessControl.find(new_resource.access_control_id)
      if ac.contains.empty?
        logger.info "Destroy and eradicate #{new_resource.access_control_id}"
        ac.destroy.eradicate
      end
      new_resource.access_control_id = nil
    end
    new_resource
  end
end
