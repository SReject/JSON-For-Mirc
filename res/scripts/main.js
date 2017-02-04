(function () {
    'use strict';

    //
    function addEvent(ele, evt, cb) {
        if (ele == null || ele == undefined) {
            return;
        }
        // standards compliant
        if (ele.addEventListener) {
            ele.addEventListener(evt, cb, false);
        // IE
        } else if (ele.attachEvent) {
            ele.attachEvent('on' + evt, cb);
        // no event listener method; no event attached
        } else if (ele['on' + evt] == undefined) {
            ele['on' + evt] = cb;
        // no event listener method; event attached
        } else {
            var next = ele['on' + evt];
            ele['on' + evt] = function (e) {
                cb.call(this, e);
                next.call(this, e);
            }
        }
    };


    addEvent(window, 'load', function (e) {

        // nav list toggling
        (function () {
            var thumb    = document.getElementById('mainnavthumb'),
                list     = document.getElementsByClassName('pagenav')[0],
                showTest = /(?:^| )show(?= |$)/;

            addEvent(thumb, 'click', function (e) {
                e.preventDefault();
                if (document.documentElement.clientWidth < 960) {
                    if (showTest.test(list.className)) {
                        list.className = list.className.replace(showTest, '');
                    } else {
                        list.className += list.className ? ' show' : 'show';
                    }
                } else if (showTest.test(list.className)) {
                    list.className = list.className.replace(showTest, '');
                }
            });

            addEvent(window, 'resize', function (e) {
                if (document.documentElement.clientWidth >= 960 && showTest.test(list.className)) {
                    list.className = list.className.replace(showTest, '');
                }
            });
        }());

        //nav sublist toggling
        (function () {
            var nav = document.getElementsByClassName("pagenav")[0],
                toggles = nav.getElementsByClassName("navsubtoggle"),
                isActive = /(?:^| )active(?= |$)/,
                isExpand = /(?:^| )expand(?= |$)/,
                i;

            for (i = 0; i < toggles.length; i += 1) {
                addEvent(toggles[i], 'click', function (e) {
                    e.preventDefault();
                    var parent = this.parentNode.parentNode;
                    if (!isActive.test(parent.className)) {
                        if (isExpand.test(parent.className)) {
                            parent.className = parent.className.replace(isExpand, '');
                        } else {
                            parent.className += parent.className ? ' expand' : 'expand';
                        }
                    }
                });
            }

            addEvent(window, 'resize', function (e) {
                var i;
                for (i = 0; i < toggles.length; i += 1) {
                    var parent = toggles[i].parentNode.parentNode;
                    if (isExpand.test(parent.className)) {
                        parent.className = parent.className.replace(isExpand, '');
                    }
                }
            });
        }());

        (function () {
            // make copying urls easier
        }());
    });
}());
