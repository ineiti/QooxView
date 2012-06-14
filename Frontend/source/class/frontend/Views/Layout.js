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
  		this.alignTabs = "left"
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
        alignTabs: null,
        parentLayout: null,
        initValues: null,
        
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
                    case "callback_button":
//						aform.fadeOut();
						enable = false;
						unfade = false;
                        qx.util.TimerManager.getInstance().start(function(userData, timerId){
                            dbg(3, "Timer for callback_button");
							this.callBackend("button", res.data, this.fields.getFieldsData());
                        }, null, aform, null, 1000 );
                        break;
                    case "child":
                    	if ( aform.fields.childLayout ){
                    		aform.fields.childLayout.dispatch( res.data );
                    	}
                    	break;
                    case "clear":
                        this.root.removeAll();
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
                    case "empty":
                        // By default empties only normal fields. If given a list of
                        // names, clears also these lists
                        this.getActiveForm().fields.clearData(res.data);
                        break;
                    case "empty_all":
                        // Let's empty everything
                        this.getActiveForm().fields.clearDataAll();
                        break;
                    case "empty_only":
                        // Only empties the given fields (usually lists)
                        this.getActiveForm().fields.clearDataOnly(res.data);
                        break;
                    case "focus":
                        var f = res.data;
                        if ( aform && aform.fields && aform.fields.fields ){
                            if ( aform.fields.fields[f] ){
                      	        dbg( 2, "Focusing on " + f)
                      	        aform.fields.focus_if_ok( aform.fields.fields[f] );
                     		} else {
                        		dbg( 2, "Not found " + f + " in " +
                            	print_a( aform.fields.fields ) );
                      		}
                      	} else {
                      		dbg( 3, "No form -" + aform + "- or fields found");
                      	}
                     	break;
                    case "hide":
                    	this.setVisibility( res.data, 'excluded' );
                    	break;
                    case "init_values":
                    	var tab = res.data[0];
                    	var values = res.data[1];
                    	dbg( 2, "init_values for " + tab + " - " + print_a( values ) );
                    	var f = null;
                    	for (var v = 0; v < this.views.length; v++){
                    		dbg( 2, "Looking for " + this.views[v].qv_id )
                    		if ( this.views[v].qv_id == tab ){
		                    	dbg( 2, "Found " + this.views[v] );
		                    	this.views[v].initValues = values;
                    		}
                    	}
                    	break;
                    case "list":
                        this.createViews(res.data);
                        break;
                    case "parent":
                    	if ( this.parentLayout ){
                    		this.parentLayout.dispatch( res.data );
                    	}
                        break;
                    case "pass_tabs":
                    	aform.fields.childLayout.getActiveForm().callBackend( res.data[0],
                          res.data[1], res.data[2]);
                      	break;
                    case "reload":
                        window.location.reload();
                        break;
                    case "session_id":
                        rpc.session_id = res.data;
                        break;
                    case "show":
                        this.showView(res.data);
                        aform = this.getActiveForm();
                        //enable = false;
                        break;
                    case "switch_tab":
                    	for (var v = 0; v < this.views.length; v++) {
                    		if (this.views[v].qv_id == res.data) {
                    			this.tabs.setSelection([this.views[v]]);
                    			dbg( 3, "Found new tab: " + res.data);
                    			dbg( 3, "New tab is: " + this.tabs.getSelection()[0].qv_id );
                    		}
                    	}
                    	break;
                    case "unhide":
                      this.setVisibility( res.data, 'visible' );
                      break;
                    case "update":
                        if (this.tabs) {
                            this.tabs.setEnabled(true);
                        }
                        this.updateView(res.data)
                        break;
                    case "window_hide":
                        aform.fields.window_hide(res.data);
                        break;
                    case "window_show":
                    	enable = false;
                        aform.fields.window_show(res.data);
                        break;
                }
            }
            
            if (enable && aform) {
            	if ( aform.fields.getContainerElement().getDomElement() ){
                	dbg(5, "** UNdoing effects");
	                var effect = new qx.fx.effect.core.Fade(aform.fields.getContainerElement().getDomElement());
	                effect.set({
	                    from: 0.5,
	                    to: 1,
	                    duration: 0.25
	                });
	                if (aform.effect) {
	                    aform.effect.cancel();
	                }
	                effect.start();
	                aform.fields.windows_fade_to(1);
	            }
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
                if (this.tabs.getSelection()[0].qv_id != this.viewClass) {
                    alert("Changed tabs in the meantime: " +
                    this.tabs.getSelection()[0].qv_id );
                    for (var v = 0; v < this.views.length; v++) {
                        if (this.views[v].qv_id == this.viewClass) {
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
                this.field = new frontend.Views.Form(cback, this.layoutView, 
                	this.dataClass, this.viewClass, this);
                if ( this.viewClass.search( /Tabs$/ ) >= 0 ){
                  // Sub-tabbed tabs get all the width
                  container.add( this.field, {width: "100%", height: "100%"} );
                } else {
                  container.add( this.field );
                  if ( this.parentLayout ){
                  	dbg( 3, "We're in a sub-layout, adding parentLayout to fields" );
                    this.field.fields.parentLayout = this.parentLayout;
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
            
            this.tabs = new qx.ui.tabview.TabView(this.alignTabs).set("Enabled", false);
            
            this.views = [];
            for (var v = 0; v < views.length; v++) {
                dbg(2, "adding view-tab: " + views[v][0] + " - " + views[v][1]);
                this.views[v] = new qx.ui.tabview.Page(views[v][1]);
                this.views[v].qv_id = views[v][0]
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
            
            qx.event.Registration.addListener(this.tabs, "changeSelection", this.changeView, this);
            rpc.callRPC("View." + views[0][0], "show", this, this.dispatch);
            this.tabs.setSelection([this.views[0]]);
        },
        // Every time the view changes, this is called, which calls the Backend, which will call showView
        changeView: function(e){
            this.checkTimer();
            var newView = e.getData()[0].qv_id;//.getSelection()[0];
            dbg(3, "New view is: " + newView)
            this.field = this.getActiveForm();
            var container = this.getRootContainer();
            var tabSel = this.tabs.getSelection()[0];
            this.tabs.setEnabled(false);
            var inTabs = "";
            var parentFields = null;
            if ( this.parentLayout ){
            	// We're in one of the sub-tabs, so let's send along the parent-
            	// stuff
            	dbg(3, "Adding something to the show - update_view");
            	inTabs = "tabs_";
            	parentFields = this.parentLayout.field.fields.getOwnFieldsData();
            } else if ( this.field && this.field.fields ) {
            	parentFields = this.field.fields.getOwnFieldsData();
            }
            if ( tabSel.initValues ){
            	dbg( 2, "initValue for " + tabSel );
            	for ( var i in tabSel.initValues ){
            		parentFields[i] = tabSel.initValues[i];
            	}
            	dbg( 2, "parentFields is " + print_a( parentFields ) );
            	tabSel.initValues = null;
            }
            if (!container.hasChildren()) {
                dbg(3, "changeView with data " + newView + " and field " + this.field);
                rpc.callRPC("View." + newView, inTabs + "show", 
                this, this.dispatch, parentFields );
            }
            else {
                dbg(3, "Tab already created - updating only - " + print_a( parentFields ));
                this.viewClass = newView;
                rpc.callRPC("View." + newView, inTabs + "update_view", 
                this, this.dispatch, parentFields);
                // If there are kids, update them
	            if ( this.field.fields.childLayout ){
    	          	dbg(3, "Updating children" );
        	      	if ( this.field.fields.childLayout.field ){
               			var child = this.field.fields.childLayout;
               			var newView = child.tabs.getSelection()[0].qv_id;
	            		var parentFields = this.field.fields.getOwnFieldsData();
		                rpc.callRPC("View." + newView, "tabs_update_view", 
    		            child, child.dispatch, parentFields);
            	  	}
	            }
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
