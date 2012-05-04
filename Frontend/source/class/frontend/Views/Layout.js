/* ************************************************************************
 Copyright: 2010 by Linus Gasser
 License: GPL v3
 Authors: Linus Gasser
 ************************************************************************ */
/* ************************************************************************
 #asset(frontend/*)
 ************************************************************************ */
/**
 * Create the views in a Gestion-project
 */
qx.Class.define("frontend.Views.Layout", {
    //	extend : qx.core.Object,
    extend: qx.ui.container.Composite,
    
    /*
     * Constructor of Views.Chooser Takes:
     *
     */
    construct: function( ){
  		this.align_tabs = "left"
        this.base(arguments);
        this.setLayout(this.layout = new qx.ui.layout.Canvas());
        this.timer = qx.util.TimerManager.getInstance();
        this.effect = false;
        
        // this adds the container manager in one go
        this.root = new qx.ui.container.Composite(new qx.ui.layout.Canvas());
        this.root.setPadding(10);
        
        this.add(this.root, {width: "100%", height: "100%"});
        
        this.addListener("resize", function(e){
            root.fireDataEvent("resize", new qx.event.type.Data());
        }, this);
    },
    members: {
        layoutView: null,
        dataClass: null,
        viewClass: null,
        root: null,
        views: null,
        layout: null,
        list: null,
        views: null,
        field: null,
        tabs: null,
        timer: null,
        effect: null,
        timerUpdate: null,
        align_tabs: null,
        tabs_field: null,
        
        // Resizes the root-widget to maximum size in case of a tab-widget
        resizeTab: function(){
            if (this.tabs) {
                dbg(0, "New Width is " + qx.bom.Viewport.getWidth());
                this.root.setWidth(qx.bom.Viewport.getWidth());
                this.root.setHeight(qx.bom.Viewport.getHeight());
            }
        },
        // This is called upon return from the server, and dispatches to the
        // appropriate functions. The result is an array of commands.
        dispatch: function(results){
            dbg(5, "in dispatcher for " + this.viewClass);
			var enable = true;
            // Cleaning up effects and disabling of stuff
            var aform = this.getActiveForm();
            if (aform && !aform.fields.isEnabled()) {
                aform.fields.setEnabled(true);
            }
            
            for (var r = 0; r < results.length; r++) {
                var res = results[r];
                dbg(0, "*****===== Dispatcher " + (r + 1) + " / " + results.length)
                dbg(0, print_a(res));
                dbg(0, print_a(res.data));
                dbg(0, res.data);
                switch (res.cmd) {
                    case "session_id":
                        rpc.session_id = res.data;
                        break;
                    case "show":
                        this.showView(res.data);
                        break;
                    case "update":
                        if (this.tabs) {
                            this.tabs.setEnabled(true);
                        }
                        this.updateView(res.data)
                        break;
                    case "list":
                        this.createViews(res.data);
                        break;
                    case "clear":
                        this.root.removeAll();
                        break;
                    case "reload":
                        window.location.reload();
                        break;
                    case "empty":
                        // By default empties only normal fields. If given a list of
                        // names, clears also these lists
                        this.getActiveForm().fields.clearData(res.data);
                        break;
                    case "empty_only":
                        // Only empties the given fields (usually lists)
                        this.getActiveForm().fields.clearDataOnly(res.data);
                        break;
                    case "emtpy_all":
                        // Let's empty everything
                        this.getActiveForm().fields.clearDataAll();
                        break;
                    case "debug":
                        // Enable logging in debug variant
                        dbg(0, "Turning debugging on")
                        if (qx.core.Environment.get('qx.debug') != "on") {
                            // support native logging capabilities, e.g. Firebug for Firefox
                            qx.log.appender.Native;
                            // support additional cross-browser console. Press F7 to toggle
                            // visibility
                            qx.log.appender.Console.show();
                        }
                        break;
                    case "auto_update":
                        // Enable an automatic update every n seconds
                        this.checkTimer();
                        // The time is positive if we only ask the backend to send new data
                        // The time is negative if we have to send our values first
                        var time = Math.abs(res.data) * 1000;
                        var method = "update";
                        if (res.data < 0) {
                            method = "update_with_values"
                        }
                        dbg(3, "update-method is: " + method);
                        dbg(3, "View is: " + this.viewClass)
                        this.timerUpdate = this.timer.start(function(userData, timerId){
                            dbg(3, "timer for update")
                            var values = [];
                            if (method == "update_with_values") {
                                values = [this.field.fields.getFieldsData()];
                                dbg(3, "Values are: " + print_a(values));
                            }
                            rpc.callRPCarray("View." + this.viewClass, method, this, this.dispatch, values);
                        }, time, this, null, time);
                        break;
                    case "window_show":
                    	enable = false;
                        aform.fields.window_show(res.data);
                        break;
                    case "window_hide":
                        aform.fields.window_hide(res.data);
                        break;
                    case "callback_button":
//						aform.fadeOut();
						enable = false;
						unfade = false;
                        qx.util.TimerManager.getInstance().start(function(userData, timerId){
                            dbg(3, "Timer for callback_button");
							this.callBackend("button", res.data, this.fields.getFieldsData());
                        }, null, aform, null, 1000 );
                        break;
                    case "switch_tab":
                    	for (var v = 0; v < this.views.length; v++) {
                    		if (this.views[v].getLabel() == res.data) {
                    			this.tabs.setSelection([this.views[v]]);
                    			dbg( 3, "Found new tab: " + res.data);
                    			dbg( 3, "New tab is: " + this.tabs.getSelection()[0].getLabel() );
                    		}
                    	}
                    	break;
                    case "hide":
                      this.setVisibility( res.data, 'excluded' );
                      break;
                    case "unhide":
                      this.setVisibility( res.data, 'visible' );
                      break;
                    case "pass_tabs":
                      aform.fields.layout.getActiveForm().callBackend( res.data[0],
                        res.data[1], res.data[2]);
                      break;
                }
            }
            
            if (enable && aform) {
                dbg(5, "** UNdoing effects");
                var effect = new qx.fx.effect.core.Fade(aform.fields.getContainerElement().getDomElement());
                effect.set({
                    from: 0.5,
                    to: 1
                });
                if (aform.effect) {
                    aform.effect.cancel();
                }
                effect.start();
                aform.fields.windows_fade_to(1);
            }
            if (this.tabs && enable) {
                this.tabs.setEnabled(true);
            }
            if (this.field) {
                dbg(5, "setting updating on false in " + this.field);
                this.field.fields.updating = false;
            }
            dbg(5, "finished dispatcher");
        },
        
        setVisibility: function( el, vi ){
        	aform = this.getActiveForm();
            if ( aform.fields.fields[el] ){
                aform.fields.fields[ el ].setVisibility(vi);
            } else {
               	dbg( 3, "Didn't find field " + el );
            }
        },
        
        checkTimer: function(){
            dbg(3, "checkTimer");
            if (this.timerUpdate) {
                dbg(2, "Killing running timer");
                this.timer.stop(this.timerUpdate);
                this.timerUpdate = null;
            }
        },
        // Displays the chosen view of the user
        showView: function(results){
            this.layoutView = results.layout;
            this.dataClass = results.data_class;
            this.viewClass = results.view_class;
            dbg(5, "We have to show the following: " + this.layoutView);
            
            this.checkTimer();
            
            // Assure we're in the right tab
            if (this.tabs) {
                if (this.tabs.getSelection()[0].getLabel() != this.viewClass) {
                    alert("Changed tabs in the meantime: " +
                    this.tabs.getSelection()[0].getLabel());
                    for (var v = 0; v < this.views.length; v++) {
                        if (this.views[v].getLabel() == this.viewClass) {
                            this.tabs.setSelection([this.views[v]]);
                        }
                    }
                }
            }
            
            var container = this.getRootContainer();
            dbg(5, "showView - container is: " + container);
            var cback = [this, this.dispatch];
            // dbg(5, "cback in showView is " + print_a(cback))
            if (!container.hasChildren()) {
                dbg(4, "Adding container " + this.viewClass);
                this.field = new frontend.Views.Form(cback, this.layoutView, this.dataClass, this.viewClass);
                if ( this.viewClass.search( /Tabs$/ ) >= 0 ){
                  // Sub-tabbed tabs get all the width
                  container.add( this.field, {width: "100%", height: "100%"} );
                  // Allow access to the main-tab
                  this.field.fields.layout.tabsField = this.field.fields;
                } else {
                  container.add( this.field );
                  if ( this.tabsField ){
                  	dbg( 3, "We're in a sub-layout, adding tabsField" );
                  	this.field.fields.tabsField = this.tabsField;
                  }
                }
                this.field.fields.focus_if_ok( this.field.fields.first_field);
            }
            else {
                dbg(4, "Layout " + this.viewClass + " already here - doing nothing");
            }
        },
        updateView: function(results){
            dbg(4, "updateView: " + results)
            if (results) {
                this.field.fields.fill(results);
            }
        },
        createViews: function(results){
            var views = results.views
            dbg(5, "The following views are allowed: " + views);
            
            this.root.removeAll();
            
            this.tabs = new qx.ui.tabview.TabView(this.align_tabs).set("Enabled", false);
            // alert( "Enabled is false");
            
            this.views = [];
            for (var v = 0; v < views.length; v++) {
                dbg(2, "adding view-tab: " + views[v]);
                this.views[v] = new qx.ui.tabview.Page(views[v]);
                this.views[v].setLayout(new qx.ui.layout.Canvas());
                var scroller = new qx.ui.container.Scroll();
                var composite = new qx.ui.container.Composite();
                composite.setLayout(new qx.ui.layout.Canvas());
                scroller.add(composite);
                this.views[v].add(scroller, {
                    width: "100%",
                    height: "100%"
                });
                this.tabs.add(this.views[v]);
            }
            this.root.add(this.tabs, {
                width: "100%",
                height: "100%"
            });
            dbg(3, "getRootContainer gives: " + this.getRootContainer());
            
            // alert( "Registering");
            qx.event.Registration.addListener(this.tabs, "changeSelection", this.changeView, this);
            // alert( "calling rpc");
            rpc.callRPC("View." + views[0], "show", this, this.dispatch);
            // alert( "finished");
            this.tabs.setSelection([this.views[0]]);
        },
        // Every time the view changes, this is called, which calls the Backend, which will call showView
        changeView: function(e){
            this.checkTimer();
            var newView = e.getData()[0].getLabel();//.getSelection()[0];
            dbg(3, "New view is: " + newView)
            this.field = this.getActiveForm();
            var container = this.getRootContainer();
            this.tabs.setEnabled(false);
            if (!container.hasChildren()) {
                dbg(3, "changeView with data " + newView + " and field " + this.field);
                rpc.callRPC("View." + newView, "show", this, this.dispatch);
            }
            else {
                dbg(3, "Tab already created - updating only");
                this.viewClass = newView;
                rpc.callRPC("View." + newView, "update_view", this, this.dispatch);
            }
        },
        // Helper function to get to the active form
        getActiveForm: function(){
            var base = this.getRootContainer();
            if (base.getChildren) {
                return base.getChildren()[0];
            }
            else {
                return null;
            }
        },
        getRootContainer: function(){
            dbg(5, "getActiveForm");
            return this.tabs ? this.tabs.getSelection()[0].getChildren()[0].getChildren()[0] : this.root;
        }
    }
});
