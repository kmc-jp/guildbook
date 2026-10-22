require_relative 'support'

RSpec.describe 'GuildBook integration tests', type: :feature do
  it 'lists active users and follows a profile link' do
    visit '/'
    expect(page.status_code).to eq(200)
    within '#basic-list' do
      expect(page).to have_link('komachi')
      expect(page).to have_link('chie')
      expect(page).not_to have_link('combat')
      click_link 'komachi'
    end
    expect(page).to have_current_path('/komachi')
    expect(page).to have_link('komachi@example.test', href: 'mailto:komachi@example.test')
    expect(page).to have_content('42代')
    expect(page).to have_content('烏丸 こまち')
    expect(page).to have_content('テスト大学 テスト学部')
  end

  it 'searches users using the search form' do
    visit '/'
    fill_in 'q', with: 'komachi'
    click_button '検索'
    within '#basic-list' do
      expect(page).to have_link('komachi')
      expect(page).not_to have_link('chie')
    end
  end

  it 'can include inactive users' do
    visit '/?all=1'
    within '#basic-list' do
      expect(page).to have_link('combat')
    end
  end

  it 'shows only members of the admin group' do
    visit '/!group/admin'
    expect(page.status_code).to eq(200)
    within '#basic-list' do
      expect(page).to have_link('komachi')
      expect(page).not_to have_link('chie')
    end
  end

  it 'rejects an incorrect password before displaying the editor' do
    visit '/komachi/edit'
    fill_in 'bind-password', with: 'incorrect-password'
    click_button '送信'
    expect(page).to have_css('.alert-danger')
    expect(page).not_to have_button('保存')
    expect(page).not_to have_field('edit-surname')
  end

  it 'authenticates, edits a profile, and reads the saved LDAP attributes' do
    visit '/komachi'
    click_link '編集'
    fill_in 'bind-password', with: 'integration-password'
    click_button '送信'
    expect(page).to have_field('edit-surname', with: 'Karasuma')
    fill_in 'description', with: 'Updated through Capybara'
    fill_in 'bind-password', with: 'integration-password'
    click_button '保存'
    expect(page).to have_current_path('/komachi')
    expect(page).to have_content('Updated through Capybara')

    user = GuildBook::UserRepo.new(GuildBook::App.settings.ldap_uri['users']).get('komachi')
    expect(user['description']).to eq(['Updated through Capybara'])
    expect(Date.parse(user['x-kmc-LastModified'].first)).to eq(Date.today)
  end

  it 'renders the university roster' do
    visit '/!univ'
    expect(page.status_code).to eq(200)
    expect(page).to have_css('table#members')
    expect(page).to have_content('構成員名簿')
    within 'table#members' do
      expect(page).not_to have_content('烏丸 こまち')
    end
  end

  it 'renders the checklist' do
    visit '/!checklist'
    expect(page.status_code).to eq(200)
    expect(page).to have_content('OB/OG')
    expect(page).to have_content('chie(40)')
  end

  it 'renders the account creation and password change forms' do
    visit '/!adduser'
    expect(page.status_code).to eq(200)
    expect(page).to have_css('form[action$="/!adduser"]')
    visit '/!passwd/komachi'
    expect(page.status_code).to eq(200)
    expect(page).to have_field('edit-password')
    expect(page).to have_field('edit-password-confirm')
  end

  it 'returns 404 for an unknown user' do
    visit '/nonexistent'
    expect(page.status_code).to eq(404)
  end
end
