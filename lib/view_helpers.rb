module GuildBook
  module ViewHelpers
    def input_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-control'
      haml_tag :input, {name: attr, value: user[attr].first}.merge(opt)
    end
    def select_userattr(user, attr, values, show_default, opt = {})
      opt[:class] ||= 'form-select'
      haml_tag :select, {name: attr}.merge(opt) do
        if show_default
          haml_tag :option, selected: true, hidden: true, value: "" do haml_concat "--選択してください--" end
        end
        current_value = user[attr].first
        values.each do |k, v|
          selected = k == current_value
          haml_tag :option, value: k, selected: selected do haml_concat v end
        end
      end
    end
  end
end
