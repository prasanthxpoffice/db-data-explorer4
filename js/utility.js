(function (window) {
    window.AppUtils = {
        /**
         * Returns default configuration for jqGrid
         * @returns {Object} Default jqGrid options
         */
        getGridDefaults: function () {
            return {
                datatype: "local",
                viewrecords: true,
                shrinkToFit: false,
                height: 'auto',
                rowNum: 20
            };
        },

        /**
         * Merges default grid options with custom options
         * @param {Object} customOptions - Custom jqGrid options
         * @returns {Object} Merged options
         */
        getGridConfig: function (customOptions) {
            // Determine direction based on current language
            var lang = (window.i18n && window.i18n.currentLang) ? window.i18n.currentLang : 'en-US';
            var direction = (lang === 'ar-AE' || lang === 'ar') ? 'rtl' : 'ltr';

            var defaults = this.getGridDefaults();
            // Merge direction into defaults (can be overridden by customOptions)
            defaults.direction = direction;

            var options = $.extend({}, defaults, customOptions);

            // Wrap loadComplete to handle pager visibility
            var originalLoadComplete = options.loadComplete;
            options.loadComplete = function (data) {
                // Call original loadComplete if it exists
                if (originalLoadComplete) {
                    originalLoadComplete.call(this, data);
                }

                // Auto-hide pager logic
                var $grid = $(this);
                var pagerSelector = options.pager;
                if (pagerSelector) {
                    var records = $grid.jqGrid('getGridParam', 'records');
                    var rowNum = $grid.jqGrid('getGridParam', 'rowNum');

                    if (records <= rowNum) {
                        $(pagerSelector).hide();
                    } else {
                        $(pagerSelector).show();
                    }
                }
            };

            return options;
        },

        /**
         * Creates and opens a jQuery UI modal dialog
         * @param {string} selector - Selector for the modal content container
         * @param {Object} options - jQuery UI Dialog options
         */
        createModal: function (selector, options) {
            var defaults = {
                autoOpen: false,
                modal: true,
                resizable: false,
                closeText: "x",
                width: 400,
                position: { my: "center", at: "center", of: window }
            };
            var settings = $.extend({}, defaults, options);

            // Initialize if not already initialized
            if (!$(selector).hasClass('ui-dialog-content')) {
                $(selector).dialog(settings);
            }

            return $(selector);
        }
    };
})(window);
