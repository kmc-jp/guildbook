module Haml
  module Helpers
    def input_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-control'
      haml_tag :input, {name: attr, value: user[attr].first}.merge(opt)
    end

    def textarea_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-control'
      haml_tag :textarea, preserve(html_escape(user[attr].first)), {name: attr}.merge(opt)
    end
  end
end
