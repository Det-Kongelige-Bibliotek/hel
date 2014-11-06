$(document).ready(function(){
    $('[data-function="new-controlled_list-entry"]').click(function(){
        var html = '<div class="empty-entry">' + $('.empty-entry').first().html() + '</div>'

        $('[data-hook="empty-entries"]').append(html);
        return false;
    })
});