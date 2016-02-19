$(document).ready(function() {
    var mypage = window.location.hash;
    (mypage.indexOf("#facs") > -1)? $('#facs').addClass('active') : $('#text').addClass('active');
});