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
            }else{
                // If the json file is empty, an alert message appears.
                alert("No data to import.");
            }
        }
    });
}
// Function for the VIAF autocomplete
$(function() {
    $("#myViafId").viafautox( {
        select: function(event, ui){
            var item = ui.item;
            // Create the URI and give it as input
            $('#authority_person_same_as_uri').val("http://viaf.org/viaf/" + item.id)
        },
        nomatch: function(event, ui) {
            // Alert box if there is no match
            var val = $(event.target).val();
            alert("No match was found for: " + val);
        }
    });
});