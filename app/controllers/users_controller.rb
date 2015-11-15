class UsersController < ApplicationController
  def index
    if params[:q].present?
      query = "*#{ActiveLdap::Escape.ldap_filter_escape(params[:q])}*"
      filter = [:or, *SEARCHABLE_ATTRS.map {|attr| [attr, query] }]
    end

    if params[:all].blank?
      filter = [:and, filter, [:not, ['shadowExpire', '*']]]
    end

    @users = sort(User.all(filter: filter), sort_keys: params[:sort])
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    @user.assign_attributes(update_params(params))
    begin
      @user.bind(bind_dn: @user.find(params[:bind][:uid]).dn, password: params[:bind][:password])
      @user.save!
      redirect_to user_url(@user)
    rescue
      flash.now[:danger] = $!.message
      render :edit
    ensure
      @user.remove_connection
    end
  end

  private

  SEARCHABLE_ATTRS = %w[uid name]

  EDITABLE_ATTRS = %w[
    cn
    sn sn;lang-ja x_kmc_phonetic_surname gn gn;lang-ja x_kmc_phonetic_given_name
    x_kmc_university_department x_kmc_university_status x_kmc_university_matric_year
    x_kmc_alias title x_kmc_generation description
    postal_code postal_address x_kmc_lodging
    telephone_number
  ]

  def sort(users, sort_keys: nil)
    sort_keys = [*sort_keys, Settings.ui.default_sort_keys].compact.flat_map(&method(:parse_sortkeys))

    users.sort do |u, v|
      sort_keys.inject(0) do |x, (key, ord)|
        x.nonzero? || (u[key, true].map(&method(:tokenize)) <=> v[key, true].map(&method(:tokenize))) * ord
      end
    end
  end

  def parse_sortkeys(s)
    s.split(',').map {|key| key[0] != '-' ? [key, 1] : [key[1..-1], -1] }
  end

  def tokenize(s)
    s.to_s.split(/(\d+)|\s+/).map {|t| t =~ /\A\d+\z/ ? t.to_i : t }
  end

  def update_params(params)
    p = params.require(:user).permit(EDITABLE_ATTRS)
    p['cn'] = "#{p['gn']} #{p['sn']}"

    p.inject({}) do |hash, (key, value)|
      if key.include?(';')
        key, subtype = key.split(';', 2)
        value = {subtype => value}
      end

      hash[key] = [*hash[key], value]
      hash
    end
  end
end
