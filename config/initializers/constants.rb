
# The name on the button for performing the preservation
PERFORM_PRESERVATION_BUTTON = 'Perform preservation'

# The message type for a preservation request.
MQ_MESSAGE_TYPE_PRESERVATION_REQUEST = 'PreservationRequest'
# The message type for a dissemination request for BifrostBooks.
MQ_MESSAGE_TYPE_DISSEMINATION_BIFROST_BOOKS_REQUEST = 'BifrostBooksDisseminationRequest'

# The name of the datastreams, which are not to be retrieved for messages.
# DC = The Fedora internal Dublin-Core.
# RELS_EXT = The Fedora datastream for relationships.
# content = The content file, e.g. for BasicFile. (This has to be downloaded separately.)
# thumbnail = The thumbnail content file for a image file. (Not preservable.)
# rightsMetadata = The Hydra rights metadata format (Not preservable).
NON_RETRIEVABLE_DATASTREAM_NAMES = ['DC', 'RELS-EXT', 'content', 'rightsMetadata', 'thumbnail'];

# The value for the cascading checkbox for the preservation and administration view, when it is turned on and set to true.
CASCADING_EFFECT_TRUE = '1'

#######################
# PRESERVATION_STATES
#######################

# The state when the preservation has not yet begun.
PRESERVATION_STATE_NOT_STARTED = {'PRESERVATION_NOT_STARTED' => {
    'error' => false, 'color' => 'none', 'text' => 'Not started'}}

# The state for when the preservation has been initiated on Valhal-side (e.g. preservation message sent)
PRESERVATION_STATE_INITIATED = {'PRESERVATION_STATE_INITIATED' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'Preservation initiated'}}

# The state for when the preservation has been initiated on Valhal-side (e.g. preservation message sent)
PRESERVATION_REQUEST_SEND = {'PRESERVATION_REQUEST_SEND' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'Preservation initiated'}}

# Preservation request received by Yggdrasil and understood (i.e. the message is complete).
PRESERVATION_REQUEST_RECEIVED = {'PRESERVATION_REQUEST_RECEIVED' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'Preservation request received by Yggdrasil'}}

# Preservation request received by Yggdrasil, but it is incomplete. Something is missing. Failstate.
PRESERVATION_REQUEST_RECEIVED_BUT_INCOMPLETE = {'PRESERVATION_REQUEST_RECEIVED_BUT_INCOMPLETE' => {
    'error' => true, 'color' => 'red', 'text' => 'Preservation request is incomplete and cannot be handled by Yggdrasil.'}}

# Yggdrasil has downloaded metadata from Valhal successfully.
PRESERVATION_METADATA_DOWNLOAD_SUCCESS = {'PRESERVATION_METADATA_DOWNLOAD_SUCCESS' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'Preservation metadata downloaded successfully.'}}

# Yggdrasil has experienced an error while downloading metadata from Valhal. Failstate.
PRESERVATION_METADATA_DOWNLOAD_FAILURE = {'PRESERVATION_METADATA_DOWNLOAD_FAILURE' => {
    'error' => true, 'color' => 'red', 'text' => 'Yggdrasil could not download the metadata from Valhal.'}}

# Yggdrasil has packaged the metadata successfully.
PRESERVATION_METADATA_PACKAGED_SUCCESSFULLY = {'PRESERVATION_METADATA_PACKAGED_SUCCESSFULLY' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'Yggdrasil has successfully packaged the metadata.'}}

# Yggdrasil could not successfully package the metadata (eg. METS error or similar). Failstate.
PRESERVATION_METADATA_PACKAGED_FAILURE = {'PRESERVATION_METADATA_PACKAGED_FAILURE' => {
    'error' => true, 'color' => 'red', 'text' => 'Yggdrasil could not package the metadata.'}}

# Yggdrasil has successfully downloaded the resources from Valhal.
PRESERVATION_RESOURCES_DOWNLOAD_SUCCESS = {'PRESERVATION_RESOURCES_DOWNLOAD_SUCCESS' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'Yggdrasil has successfully downloaded the resources from Valhal'}}

# Yggdrasil has experienced an error while downloading the resources. Failstate.
PRESERVATION_RESOURCES_DOWNLOAD_FAILURE = {'PRESERVATION_RESOURCES_DOWNLOAD_FAILURE' => {
    'error' => true, 'color' => 'red', 'text' => 'Yggdrasil could not download the resource file from Valhal.'}}

# Yggdrasil finished packaging (metadata and ressources written to the WARC format) and ready to initiate upload.
PRESERVATION_PACKAGE_COMPLETE = {'PRESERVATION_PACKAGE_COMPLETE' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'Yggdrasil has finished packaging into a WARC file.'}}

# Yggdrasil waiting for more requests before upload is initiated.
# If the request does not have the requirement, that it should be packaged in its own package.
# Then it arrives into this state. However, we can only package data together with
# the same bitrepository profile. So each profile must have its own waiting queue.
PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA = {'PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'Yggdrasil is waiting for more data before uploading the WARC file.'}}

# Yggdrails has initiated upload to Bitrepository.
PRESERVATION_PACKAGE_UPLOAD_INITIATED = {'PRESERVATION_PACKAGE_UPLOAD_INITIATED' => {
    'error' => false, 'color' => 'limegreen', 'text' => 'WARC file is being uploaded to the BitRepository.'}}

# Upload to Bitrepository failed. Failstate.
PRESERVATION_PACKAGE_UPLOAD_FAILURE = {'PRESERVATION_PACKAGE_UPLOAD_FAILURE' => {
    'error' => true, 'color' => 'red', 'text' => 'The WARC file has failed to be uploaded to the BitRepository.'}}

# Upload to Bitrepository was successful.
PRESERVATION_PACKAGE_UPLOAD_SUCCESS = {'PRESERVATION_PACKAGE_UPLOAD_SUCCESS' => {
    'error' => false, 'color' => 'skyblue', 'text' => 'Preservation complete.'}}

# The state for failures, which does not fit in any of the other states.
PRESERVATION_REQUEST_FAILED = {'PRESERVATION_REQUEST_FAILED' => {
    'error' => false, 'color' => 'red', 'text' => 'Preservation failure'}}

PRESERVATION_STATE_NOT_LONGTERM = {'PRESERVATION_STATE_NOT_LONGTERM' => {
    'error' => false, 'color' => 'skyblue', 'text' => 'Not longterm preservation.'}}

# The complete hash of the valid states and their values. (No easy way of merging hashes, therefore this 'hack')
PRESERVATION_STATES = Hash.new
[PRESERVATION_STATE_NOT_STARTED,PRESERVATION_STATE_INITIATED,PRESERVATION_REQUEST_RECEIVED,
 PRESERVATION_REQUEST_RECEIVED_BUT_INCOMPLETE,PRESERVATION_METADATA_DOWNLOAD_SUCCESS,
 PRESERVATION_METADATA_DOWNLOAD_FAILURE,PRESERVATION_METADATA_PACKAGED_SUCCESSFULLY,
 PRESERVATION_METADATA_PACKAGED_FAILURE,PRESERVATION_RESOURCES_DOWNLOAD_SUCCESS,
 PRESERVATION_RESOURCES_DOWNLOAD_FAILURE,PRESERVATION_PACKAGE_COMPLETE,PRESERVATION_PACKAGE_WAITING_FOR_MORE_DATA,
 PRESERVATION_PACKAGE_UPLOAD_INITIATED,PRESERVATION_PACKAGE_UPLOAD_FAILURE,PRESERVATION_PACKAGE_UPLOAD_SUCCESS,
 PRESERVATION_REQUEST_FAILED, PRESERVATION_STATE_NOT_LONGTERM
].each {|h| PRESERVATION_STATES.merge!(h)}

PRESERVATION_STATE_INVALID = {'error' => true, 'color' => 'yellow', 'text' => 'The current preservation state is invalid.'}