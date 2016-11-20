module FormBlankHelper
  def show_blank(curation_concern)
    if curation_concern.new_record?
      false
    else
      true
    end
  end
end