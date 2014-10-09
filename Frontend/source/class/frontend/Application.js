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
            layout: null,
            lay_grid: null,
            cont_grid: null,

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

                // We start with the Welcome-view which shows a login-screen or other
                rpc.callRPC("View.Welcome", "show", this.layout, this.layout.dispatch);
            },

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
