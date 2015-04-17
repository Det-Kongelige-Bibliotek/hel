$(document).ready(function(){
    // jump to location of div within page
    // get value of xml_pointer
    var pointer = $.trim(($('#xml_pointer').text()));
    //get location of xml id in text
    var div = $("span:contains('" + pointer + "')");
    // add styling to xml id
    div.css('background-color', '#ccffff');
    var vertical_location = div.offset().top;
    //move window to this location
    $(window).scrollTop(vertical_location)
});
