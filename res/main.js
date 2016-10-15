(function ($) {
    function navToHash(e) {
        var hash = String(location.hash || "#!/home").toLowerCase(),
            match = hash.match(/^#!\/([a-z]+)(?:\/((?:[a-z]+(?:\/|$))*))?$/),
            page = "home",
            anchor = "",
            menuitem,
            anchoritem,
            newHash;
        if (match && match.length > 1) {
            menuitem = $('.menu > ul > li[data-pagename=' + match[1] + ']');
            if (menuitem.length) {
                page = match[1];
                if (match[2]) {
                    anchoritem = $('.content div[id="!/' + page + '/' + match[2] + '"]');
                    if (anchoritem.length) {
                        anchor = match[2];
                    }
                }
            }
        }
        $('.menu li').removeClass("active");
        menuitem = $('.menu > ul > li[data-pagename=' + page + ']');
        if (anchor) {
            menuitem.find('li[data-anchorname="' + anchor + '"]').addClass("active");
        } else {
            menuitem.addClass("active");
        }
        $('.content > div').removeClass("active");
        $('.content > div[name="' + page + '"]').addClass("active");
        if (anchor) {
            $(document).scrollTop( $('.content div[id="!/' + page + '/' + anchor +'"]').offset().top - 25 );
        }
        location.hash = '#!/' + page + (anchor ? '/' + anchor : '');
    }
    $(window).on('hashchange', navToHash);
    navToHash();
}(jQuery));



    

    