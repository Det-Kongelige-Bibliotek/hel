FactoryGirl.define do

  trait :valid_administrative_data do
    collection ['collection']
    activity 'activity'
    copyright 'cc'
  end

  factory :trykforlaeg do
    valid_administrative_data
    published_date '2001-02-03'
    isbn13 '9780521169004'
  end

  factory :admin, class: User do
    email "admin@kb.dk"
    password "admin123"
    name "administrator"
    member_of "CN=Chronos-Admin,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk"

    after(:create) do |user|
      user.stub(update_attributes: false)
    end
  end

end

