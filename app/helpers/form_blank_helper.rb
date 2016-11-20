module FormBlankHelper
  def show_blank(curation_concern)
    # fill the field with the first item for a new record
    # show a blank field on edit
    if curation_concern.new_record?
      false
    else
      true
    end
  end
end