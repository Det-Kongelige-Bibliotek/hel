Given(/^There are ojects in the system$/) do
  aut = Authority::Person.create!(given_name: 'James', family_name: 'Joyce')
  work = Work.new
  work.add_title(value: 'Sample title')
  work.add_author(aut)
  work.save!
end

Given(/^the user is on the login page$/) do
  visit '/users/sign_in'
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
  step 'the user is on the login page'
  step 'the user enters correct login details'
end

Then(/^the page should return successfully$/) do
  page.status_code == 200
end

Given(/^the user is not logged in$/) do
end

Then(/^the page should not return successfully$/) do
  page.status_code != 200
end

Then(/^the user should be redirected to the (.*)$/) do |path|
  page.status_code == 302
  current_path == path
end

And(/^the user fills out the work form$/) do
  within '#new_work' do
    fill_in 'work_titles_attributes_0_value', with: 'Ulysses'
    select 'Joyce, James', from: 'Agent'
    select 'Author', from: 'Role'
    select 'English', from: 'work_language'
    fill_in 'work_origin_date', with: '1922'
  end
  click_button 'Gem værk'
end

And(/^the user goes to the (.*) page$/) do |path|
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