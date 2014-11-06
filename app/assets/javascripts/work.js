var creator_counter = 0;
var title_counter = 0;

$(document).ready(function(){

    // Add/remove title functions
    $(".hidden-title").hide();
    title_counter = $(".title, .new-title, .hidden-title").length;
    $('[data-function="new-title"]').click(function(){
        hidden_title = $("div.hidden-title");
        new_title = hidden_title.clone(true)
            .find("input.title-value").attr("name","work[titles]["+title_counter+"][value]").end()
            .find("select.title-lang").attr("name","work[titles]["+title_counter+"][lang]").end()
            .find("select.title-type").attr("name","work[titles]["+title_counter+"][type]").end()
            .find("input.title-subtitle").attr("name","work[titles]["+title_counter+"][subtitle]").end();
        hidden_title.removeClass('hidden-title').addClass("title");
        hidden_title.find("select").each(function(index){
            $(this).addClass("combobox");
            $(this).combobox();
            $(this).click(function(){
                $(this).siblings('.dropdown-toggle').click();
            });
        })
        hidden_title.show();
        new_title.insertAfter(hidden_title);
        title_counter = title_counter +1;
        return false;
    });
    $('[data-function="delete-title"]').click(function(){
        $(this).parent().parent().remove();
        return false;
    })

    // Add/remove creator functions
    $(".hidden-creator").hide();
    creator_counter = $(".creator, .new-creator, .hidden-creator").length;
    $('[data-function="new-creator"]').click(function(){
        hidden_creator = $("div.hidden-creator");
        new_creator = hidden_creator.clone(true)
            .find("select.creator-id").attr("name","work[creators]["+creator_counter+"][id]").end()
            .find("select.creator-type").attr("name","work[creators]["+creator_counter+"][type]").end();
        hidden_creator.removeClass('hidden-creator').addClass("creator");
        hidden_creator.find("select").each(function(index){
            $(this).addClass("combobox");
            $(this).combobox();
            $(this).click(function(){
                $(this).siblings('.dropdown-toggle').click();
            });
        })
        hidden_creator.show();
        new_creator.insertAfter(hidden_creator);
        creator_counter = creator_counter +1;
        return false;
    });
    $('[data-function="delete-creator"]').click(function(){
        $(this).parent().parent().remove();
        return false;
    })


    // Combobox functionallity
    $('.combobox').combobox();
    $('.combobox').click(function(){
        $(this).siblings('.dropdown-toggle').click();
    });
});