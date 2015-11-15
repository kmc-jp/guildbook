class User < ActiveLdap::Base
  include ActiveModel::Conversion

  ldap_mapping dn_attribute: 'uid',
               prefix: 'ou=users',
               scope: :one,
               classes: %w[posixAccount x-kmc-Person]

  class << self
    def attr_with_lang(name)
      attr = schema.attribute(name)
      names = [attr.name, *attr.aliases].collect_concat {|n| [n.underscore, n.underscore.camelize(:lower)] }.uniq

      names.each do |name|
        define_method(name) do |force_array = false, lang: nil|
          values = self[name, true]
          values = if lang
                     values.collect_concat {|o| o["lang-#{lang}"] if o.is_a?(Hash) }.compact
                   else
                     values.select {|o| o.is_a?(String) }
                   end

          array_of(values, force_array)
        end
      end
    end
  end

  attr_with_lang :sn
  attr_with_lang :gn
end
