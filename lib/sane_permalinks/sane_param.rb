module SanePermalinks

  def permalink_options
    self.class.permalink_options
  end

  def sane_param
    sanitize_param(make_param)
  end

  def make_param
    if(!permalink_options.empty? && !permalink_options[:prepend_id])
      persisted_permalink_field
    elsif(!permalink_options.empty?)
      "#{original_to_param}-#{persisted_permalink_field}"
    else
      original_to_param
    end
  end

  def persisted_permalink_field
    field_name = permalink_options[:with]

    if self.send("#{field_name}_changed?")
      self.send("#{field_name}_was")
    else
      self.send(field_name)
    end
  end
end
