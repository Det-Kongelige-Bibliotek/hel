$(document).ready(function() {
    var myid = window.location.hash;
    if (myid) {
        (myid.indexOf("facsid") > -1)? $('#facs').addClass('active') : $('#text').addClass('active');
        $(myid)[0].scrollIntoView();
    }
    else {
        $('#text').addClass('active');
    }
});