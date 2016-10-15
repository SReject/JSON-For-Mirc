(function ($) {
    
    function navToHash() {
        var hash = String(location.hash || "#!/home"),
            match = hash.match(/^#!\/([a-z]+)(?:#((?:[a-z]+(?:\/|$))*))?$/),
            page = "home",
            anchor = "",
            menuitem,
            anchoritem,
            newHash;
        if (match && match.length > 1) {
            menuitem = $('.menu > ul > li[data-pagename=' + match[1] + ']');
            page = match[1];
            if (menuitem.length) {
                if (match[2]) {
                    anchoritem = $('.content > div[name="' + page + '"] *[name="' + match[2] + '"]');
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
        newHash = '#!/' + page + (anchor ? '#' + anchor : '');
        if (location.hash !== newHash) {
            location.hash = newHash;
        }
    }
    $(window).on('hashchange', navToHash);
    navToHash();
}(jQuery));



    

    