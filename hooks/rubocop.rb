require 'rubocop'
require 'yaml'

ADDED_OR_MODIFIED = /A|AM|^M/.freeze

ignored_files = YAML.load_file('.rubocop.yml')['AllCops']['Exclude'] rescue []

changed_files = `git status --porcelain`.split(/\n/).
    select { |file_name_with_status|
  file_name_with_status =~ ADDED_OR_MODIFIED
}.
    map { |file_name_with_status|
  file_name_with_status.split(' ')[1]
}.
    select { |file_name|
  File.extname(file_name) == '.rb'
}.
    select { |file_name|
  not ignored_files.include? file_name
}.join(' ')

system("rubocop #{changed_files}") unless changed_files.empty?

exit $CHILD_STATUS.to_s[-1].to_i