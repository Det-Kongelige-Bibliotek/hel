Given(/^There are person objects in the system$/) do
  Authority::Person.create!(given_name: 'James', family_name: 'Joyce')
  Authority::Person.create!(given_name: 'Shepard', family_name: 'Fairey')
end

Given /^the user logs in as (.*) with password (.*)$/ do |name, password|
  within '#new_user' do
    fill_in 'user_username', with: name
    fill_in 'user_password', with: password
  end
  click_button 'Log ind'
end

And(/^the user enters correct login details$/) do
  step "the user logs in as #{CONFIG[:test][:valhal_admin]} with password #{CONFIG[:test][:valhal_password]}"
end

Then(/^they should login successfully$/) do
  page.has_content? 'Du er nu logget ind'
end

And(/^the user enters incorrect login details$/) do
  step "the user logs in as not_allowed with password fakerson"
end

Then(/^they should not be allowed to login$/) do
  page.has_content? 'Email eller password er ikke gyldig.'
end

Given(/^the user is logged in$/) do
  step 'the user is on the new_user_session page'
  step 'the user enters correct login details'
end

Then(/^the page should return successfully$/) do
  expect(page.status_code).to eql 200
end

Given(/^the user is not logged in$/) do
  visit root_path
end

Then(/^the page should not return successfully$/) do
  expect(page.status_code).not_to eql 200
end

Then(/^the user should be redirected to the (.*)$/) do |path|
  page.status_code == 302
  current_path == path
end

And(/^the user fills out the work form$/) do
  within '#new_work' do
    fill_in 'work_titles_attributes_0_value', with: 'Ulysses'
    select 'Joyce, James', from: 'Agent'
    select 'Author', from: 'Rolle'
    select 'English', from: 'work_language'
    fill_in 'work_origin_date', with: '1922'
  end
  click_button 'Gem værk'
end

And(/^the user (goes to|is on) the (.*) page$/) do |method, path|
  route = send(path + '_path')
  visit route
end


# A helper to show the current page for debugging purposes
Then(/^show me the page$/) do
  save_and_open_page
end

Then(/^the work should be saved successfully$/) do
  page.has_content? I18n.t('work.save')
end

When(/^the user fills out the aleph import form with (ISBN|system nummer) (\d+)$/) do |field, val|
  within '#aleph_import' do
    select field
    fill_in 'aleph[value]', with: val
  end
  click_button 'Import'
end

When(/^the user fills out the person form$/) do
  within '#new_authority_person' do
    fill_in 'Fornavn', with: 'Siri'
    fill_in 'Efternavn', with: 'Hustvedt'
    fill_in 'Fødselsdato', with: '1955'
  end
  click_button 'Gem person'
end

Then(/^the person should be created$/) do
  page.has_content? 'oprettet'
end

When(/^the user clicks on the '(.+)' link$/) do |link_title|
  click_link link_title
end

Then(/^the content '(.+)' should not be present$/) do |text|
  page.should have_no_content(text)
end

When(/^the user fills out the mixed material form$/) do
  within '#new_mixed_material' do
    fill_in 'Titel', with: 'André The Giant Has A Posse'
    select 'Fairey, Shepard', from: 'Agent'
    select 'Author', from: 'Rolle'
    fill_in 'mixed_material_origin_date', with: '1922'
  end
end