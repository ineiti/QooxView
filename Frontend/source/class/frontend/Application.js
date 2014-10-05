/* ************************************************************************

 Copyright:

 License:

 Authors:

 ************************************************************************ */

DBG_LVL = 5;

/**
 * This is the main application class of your custom application "Frontend"
 *
 * @asset(frontend/*)
 */
qx.Class.define("frontend.Application",
    {
        extend: qx.application.Standalone,


        /*
         *****************************************************************************
         MEMBERS
         *****************************************************************************
         */

        members: {
            /**
             * This method contains the initial application code and gets called
             * during startup of the application
             *
             * @lint ignoreDeprecated(alert)
             * @require(qx.module.Attribute)
             */

            main: function () {
                // Call super class
                this.base(arguments);
                 app = this;
                root = this.getRoot();
                this.cont_grid = new qx.ui.container.Composite(
                    this.lay_grid = new qx.ui.layout.Grid(2, 2));
                this.cont_grid.add(this.layout = new frontend.Views.Ltab(this),
                    {row: 1, column: 1});
                this.cont_grid.add(new qx.ui.core.Spacer(), {row: 2, column: 2})
                this.squeezeCenter();
                root.add(this.cont_grid, {
                    width: "100%",
                    height: "100%"
                });
                if (false) {
                    this.layout.dispatch([
                        {
                            cmd: "debug"
                        }
                    ]);
                }
                rpc = new frontend.Lib.RPC;
                /*
                 */
                /* NewLayout
                 root.addListener("resize", function(e) {
                 var bounds = this.layout.getBounds();
                 if(this.layout.getChildren()) {
                 var layout = this.layout.getChildren()[0];
                 if(layout && layout.getChildren()[0]) {
                 layout = layout.getChildren()[0];
                 var size = layout.getInnerSize();
                 if(size) {
                 var top = Math.round( ( bounds.height - size.height ) / 4);
                 var left = Math.round( ( bounds.width - size.width ) / 2);
                 dbg(0, "Resizing to " + print_a(bounds) + "-" + print_a(size));
                 this.layout.set({
                 marginTop : top,
                 marginLeft : left
                 });
                 }
                 }
                 }
                 }, this);
                 */

                // We start with the Welcome-view which shows a login-screen or other
                rpc.callRPC("View.Welcome", "show", this.layout, this.layout.dispatch);
                // Create a button
                /*
                var button1 = new qx.ui.form.Button("First Button", "frontend/test.png");

                // Document is the application root
                var doc = this.getRoot();

                // Add button to document at fixed coordinates
                doc.add(button1, {left: 100, top: 50});

                // Add an event listener
                button1.addListener("execute", function (e) {
                    q('#test').setHtml('hi');
                });

                var html = new qx.ui.embed.Html();
                html.setHtml('<table><tr id="test">hello</tr></table>');
                doc.add(html);
                */
            },

            main2: function () {
                // Call super class
                this.base(arguments);

                // Enable logging in debug variant
                if (qx.core.Environment.get("qx.debug")) {
                    // support native logging capabilities, e.g. Firebug for Firefox
                    qx.log.appender.Native;
                    // support additional cross-browser console. Press F7 to toggle visibility
                    qx.log.appender.Console;
                }

                /*
                 -------------------------------------------------------------------------
                 Below is your actual application code...
                 -------------------------------------------------------------------------
                 */

                // Create a button
                var button1 = new qx.ui.form.Button("First Button", "frontend/test.png");

                // Document is the application root
                var doc = this.getRoot();

                // Add button to document at fixed coordinates
                doc.add(button1, {left: 100, top: 50});

                // Add an event listener
                button1.addListener("execute", function (e) {
                    q('#test').setHtml('hi');
                });

                var html = new qx.ui.embed.Html();
                html.setHtml('<table><tr id="test">hello</tr></table>');
                doc.add(html);
            },

            layout: null,
            lay_grid: null,
            cont_grid: null,

            squeezeCenter: function () {
                for (var i = 0; i < 3; i++) {
                    this.lay_grid.setColumnFlex(i, i != 1);
                    this.lay_grid.setRowFlex(i, ( 1 + i ) * ( i != 1 ));
                }
            },

            inflateCenter: function () {
                for (var i = 0; i < 3; i++) {
                    this.lay_grid.setColumnFlex(i, i == 1);
                    this.lay_grid.setRowFlex(i, i == 1);
                }
            }

        }
    });
