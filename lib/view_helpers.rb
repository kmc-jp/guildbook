module Haml
  module Helpers
    def input_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-control'
      haml_tag :input, {name: attr, value: user[attr].first}.merge(opt)
    end
    def select_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-select'
      haml_tag :select, {name: attr}.merge(opt) do
        haml_tag :option, :selected, value: true, '京都大学'
        haml_tag :option, value: false, 'その他'
      end
    end
  end
end
