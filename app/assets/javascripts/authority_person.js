$(document).ready(function(){
    $('[data-function="new-authorized-personal-name"]').click(function(){
        var html = '<div class="empty-name">' + $('.empty-name').first().html() + '</div>';

        $('[data-hook="empty-names"]').append(html);
        return false;
    })
});