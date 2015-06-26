// Function for importing data in the "New Person" form from VIAF
function viafImport() {
    // Create the link of the RDF record
    var link = $('#authority_person_same_as_uri').val() + '/rdf.xml';

    $.ajax({
        type: "GET",
        // Call the viaf function from the people_controller that returns a JSON
        url: "/authority/people/viaf",
        dataType: "json",
        data: {
            // The RDF record link is passed as parameter to viaf function
            url: link
        },
        success: function(response) {
            if (response.first_name){
                $('#authority_person_given_name').val(response.first_name);
                $('#authority_person_family_name').val(response.family_name);
                $('#authority_person_alternate_names').val(response.alternate_name);
                var old_field = $('#authority_person_same_as_uri')
                var new_field = old_field.clone(true);
                new_field.val(response.isni_uri);
                new_field.insertAfter(old_field);
            }else{
                // If the json file is empty, an alert message appears.
                alert("No data to import.");
            }
        }
    });
}
// Function for the VIAF autocomplete
$(document).ready(function(){

    var viafagents2 = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
            url: 'http://viaf.org/viaf/AutoSuggest?query=%QUERY&callback=?',
            wildcard: '%QUERY',
            ajax: {
                jsonp: 'callback',
                type: 'GET',
                dataType: 'jsonp'
            },
            filter: function(data) {
                return data.result;
            }
        }
    });

    $("#myViafId").typeahead({
            minLength: 1,
            highlight: true },
         {
            name: 'ViafAgents',
            source: viafagents2,
            displayKey: 'term',
            templates: {
                header: '<h3 class="agent-source">VIAF</h3>',
                empty: '<div class="empty-message">Ingen viaf agenter fundet</div>'
            }
        }).bind('typeahead:select', function(event, suggestion) {
            $('#authority_person_same_as_uri').val("http://viaf.org/viaf/" + suggestion.viafid)
        });


});