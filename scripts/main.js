(function($){
    function resize() {
        var viewSize = $(window).height(),
            contSize = $('.content').height() + 250;
            
        if (viewSize > contSize) {
            contSize = viewSize;
        }
        $('.wrapcontent').height(contSize);
    }
    

    $(window).load(function () {
       $(window).resize(resize);
       resize();
    });
}(jQuery));