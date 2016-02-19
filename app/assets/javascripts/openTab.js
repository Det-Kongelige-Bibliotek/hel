$(document).ready(function() {
    var myid = window.location.hash;
    //alert (myid);
    if (myid) {
        (myid.indexOf("facsid") > -1)? $('#facs').addClass('active') : $('#text').addClass('active');
        $(myid)[0].scrollIntoView();
    }
    else {
        $('#text').addClass('active');
    }
});