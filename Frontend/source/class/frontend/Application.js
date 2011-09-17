/* ************************************************************************
 Copyright:
 License:
 Authors:
 ************************************************************************ */
/* ************************************************************************
 #asset(frontend/*)
 ************************************************************************ */
DBG_LVL = 5;

/**
 * This is the main application class of your custom application "Frontend"
 */
qx.Class.define("frontend.Application", {
    extend: qx.application.Standalone,
    
    /*
     * ****************************************************************************
     * MEMBERS
     * ****************************************************************************
     */
    members: {
        layout: null,
        
        /**
         * This method contains the initial application code and gets called
         * during startup of the application
         *
         * @lint ignoreDeprecated(alert)
         */
        main: function(){
            // Call super class
            this.base(arguments);
            
            root = this.getRoot();
            root.add(this.layout = new frontend.Views.Layout(), {
                left: "50%",
                top: "25%"
            });
			if (false) {
				this.layout.dispatch([{
					cmd: "debug"
				}]);
			}
            
            rpc = new frontend.Lib.RPC;
            
            root.addListener("resize", function(e){
                this.layout.resizeTab();
                var bounds = this.layout.getBounds();
                var top = Math.round(-bounds.height / 4);
                var left = Math.round(-bounds.width / 2);
                this.layout.set({
                    marginTop: top,
                    marginLeft: left
                });
                dbg(0, "Resizing to " + bounds.width + " - " + bounds.height);
            }, this);
            
            // We start with the Welcome-view which shows a login-screen or other
            rpc.callRPC("View.Welcome", "show", this.layout, this.layout.dispatch)
        }
    }
});
