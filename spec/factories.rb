FactoryGirl.define do

  trait :valid_administrative_data do
    collection 'collection'
    activity 'activity'
    copyright 'cc'
  end

  factory :trykforlaeg do
    valid_administrative_data
    published_date '2001-02-03'
    isbn13 '9780521169004'
  end

end