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
  extend : qx.application.Standalone,

  /*
	 * ****************************************************************************
	 * MEMBERS
	 * ****************************************************************************
	 */
  members : {
    layout : null,

    /**
		 * This method contains the initial application code and gets called
		 * during startup of the application
		 *
		 * @lint ignoreDeprecated(alert)
		 */
    main : function() {
      // Call super class
      this.base(arguments);
      app = this;
      root = this.getRoot();
      root.add(this.layout = new frontend.Views.Ltab(), {
        width : "100%",
        height : "100%"
      });
      if(false) {
        this.layout.dispatch([{
          cmd : "debug"
        }]);
      }
      rpc = new frontend.Lib.RPC;

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
      // We start with the Welcome-view which shows a login-screen or other
      rpc.callRPC("View.Welcome", "show", this.layout, this.layout.dispatch)
    }
  }
});
