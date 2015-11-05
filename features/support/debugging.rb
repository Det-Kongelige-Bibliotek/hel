# show the current page in the browser in case of failure
After do |scenario|
  save_and_open_page if scenario.failed?
end