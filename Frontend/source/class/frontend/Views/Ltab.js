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
qx.Class.define("frontend.Views.Ltab", {
    //	extend : qx.core.Object,
    extend: qx.ui.container.Composite,

    /*
     * Constructor of Views.Chooser Takes:
     *
     */
    construct: function (app) {
        this.app = app;
        this.alignTabs = "left";
        this.fadedin = false;
        this.base(arguments);
        this.setLayout(this.layout = new qx.ui.layout.Grow());
        this.timer = new frontend.Lib.TimerF();

        this.selectfadein = "parent,child,windows";
        /*
         this.addListener("resize", function(e){
         root.fireDataEvent("resize", new qx.event.type.Data());
         }, this);
         */
    },
    members: {
        app: null,
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
        selectfadein: null,
        fadedin: null,
        alignTabs: null,
        parentLtab: null,
        initValues: null,

        dispatch_async: function (results, source) {
            source = source.replace(/^.*\./, '')
            var dest = this.viewClass
            if (this.parentLtab) {
                dest = this.parentLtab.viewClass.replace(/Tabs$/, '') +
                dest.replace(/^[A-Z][a-z]*/, '')
            }
            if (source == dest) {
                //alert( "Async of " + source + " with " + dest + " : " +
                //  this.parentLtab.viewClass );
                this.dispatch(results)
                //this.timer.cont();
            } else {
                //alert( "Oups - got " + source + " instead of " + dest )
            }
        },

        // This is called upon return from the server, and dispatches to the
        // appropriate functions. The result is an array of commands.
        dispatch: function (results) {
            dbg(5, "in dispatcher for " + this.viewClass);
            var enable = true;
            this.parentFadeOut();
            var aform = this.getActiveForm();

            for (var r = 0; r < results.length; r++) {
                var res = results[r];
                dbg(0, "*****===== Dispatcher " + (r + 1) + " / " + results.length)
                dbg(0, "res: " + print_a(res));
                //dbg(0, "res.data array: " + print_a(res.data));
                dbg(0, "res.data:" + res.data);
                switch (res.cmd) {
                    case "auto_update":
                    case "auto_update_async":
                        // Enable an automatic update every n seconds
                        this.timer.stop();
                        // The time is positive if we only ask the backend to send new data
                        // The time is negative if we have to send our values first
                        var time = Math.abs(res.data) * 1000;
                        if (time >= 1) {
                            var method = "update";
                            if (res.cmd == "auto_update_async") {
                                method = "update_async";
                            }
                            if (res.data < 0) {
                                method = method + "_with_values"
                            }
                            dbg(3, "update-method is: " + method);
                            dbg(3, "View is: " + this.viewClass);
                            this.timer.start(this.autoUpdate, time, this, method, time);
                        } else {
                            dbg(3, "auto-update is 0, not updating")
                        }
                        break;
                    case "bar_position":
                        this.tabs.setBarPosition( res.data );
                        break;
                    case "callback_button":
                        //aform.fadeOut();
                        enable = false;
                        unfade = false;
                        var callback_button = res.data
                        //alert( "Preparing callback button " + callback_button );
                        qx.util.TimerManager.getInstance().start(function (userData, timerId) {
                            dbg(3, "Timer for callback_button");
                            //alert( "Calling back button " + callback_button );
                            this.callBackend("button", callback_button, this.fields.getFieldsData());
                        }, null, aform, null, 500);
                        break;
                    case "child":
                        if (aform.fields.childLtab) {
                            aform.fields.childLtab.dispatch(res.data);
                        }
                        break;
                    case "clear":
                        this.removeAll();
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
                        // Only empties the given fields (usually lists)
                        this.getActiveForm().fields.clearDataOnly(res.data);
                        break;
                    case "empty_all":
                        // Let's empty everything
                        this.getActiveForm().fields.clearDataAll();
                        break;
                    case "empty_nonlists":
                        // By default empties only normal fields. If given a list of
                        // names, clears also these lists
                        this.getActiveForm().fields.clearData(res.data);
                        break;
                    case "empty_selections":
                        this.getActiveForm().fields.clearSelections();
                        break;
                    // Combines :empty with :update for the same field
                    case "empty_update":
                        dbg(3, "res.data is " + print_a(res.data) );
                        dbg(3, "res.data is " + print_a(Object.keys(res.data)) );
                        this.getActiveForm().fields.clearDataOnly(Object.keys(res.data));
                        this.updateView(res.data, false)
                        break;
                    // Combines :empty_all with :update
                    case "empty_all_update":
                        this.getActiveForm().fields.clearDataAll();
                        this.updateView(res.data, false)
                        break;
                    // Combines :empty_nonlists with :update
                    case "empty_nonlists_update":
                        this.getActiveForm().fields.clearData(Object.keys(res.data));
                        this.updateView(res.data, false)
                        break;
                    case "eval":
                        window.eval(res.data);
                        break;
                    case "fade_in":
                        this.setFadeIn(res.data)
                        break;
                    case "focus":
                        this.parentFadeIn();
                        var f = res.data;
                        dbg(2, "res data is " + print_a(f))
                        if (aform && aform.fields && aform.fields.fields) {
                            if (f.table) {
                                var table = aform.fields.fields[f.table];

                                if (table) {
                                    var old_update = table.updating;
                                    table.updating = true;

                                    dbg(2, "Focusing on table " + f.table);
                                    aform.fields.focus_table(table, f.col, f.row);

                                    table.updating = old_update;
                                } else {
                                    dbg(2, "Table " + f.table + " not found");
                                }
                            } else {
                                if (aform.fields.fields[f]) {
                                    dbg(2, "Focusing on " + f)
                                    aform.fields.focus_if_ok(aform.fields.fields[f]);
                                } else {
                                    dbg(2, "Not found " + f + " in " +
                                    print_a(aform.fields.fields));
                                }
                            }
                        } else {
                            dbg(3, "No form -" + aform + "- or fields found");
                        }
                        break;
                    case "hide":
                    case "unhide":
                        if (!( res.data instanceof Array )) {
                            res.data = [res.data]
                        }
                        for (var i = 0; i < res.data.length; i++) {
                            this.setElementVisibility(res.data[i],
                                res.cmd == "hide" ? "excluded" : 'visible');
                            //this.setElementVisibility( res.data[i], 'excluded' );
                        }
                        break;
                    case "init_values":
                        var tab = res.data[0];
                        var values = res.data[1];
                        dbg(2, "init_values for " + tab + " - " + print_a(values));
                        var f = null;
                        for (var v = 0; v < this.views.length; v++) {
                            dbg(2, "Looking for " + this.views[v].qv_id)
                            if (this.views[v].qv_id == tab) {
                                dbg(2, "Found " + this.views[v]);
                                this.views[v].initValues = values;
                            }
                        }
                        break;
                    case "list":
                        this.createViews(res.data);
                        break;
                    case "none":
                        dbg(5, "Doing nothing")
                        break
                    case "parent":
                        if (this.parentLtab) {
                            this.parentLtab.dispatch(res.data);
                        }
                        break;
                    case "pass_tabs":
                        aform.fields.childLtab.getActiveForm().callBackend(res.data[0],
                            res.data[1], res.data[2]);
                        enable = false;
                        break;
                    case "reload":
                        window.location.reload();
                        break;
                    case "select":
                        this.select(res.data, false)
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
                                dbg(3, "Found new tab: " + res.data);
                                dbg(3, "New tab is: " + this.tabs.getSelection()[0].qv_id);
                            }
                        }
                        break;
                    case "table_columns_show":
                        this.form.fields.set_table_columns_visible(res.data, true);
                        break;
                    case "table_columns_hide":
                        this.form.fields.set_table_columns_visible(res.data, false);
                        break;
                    case "update_silent":
                        this.updateView(res.data, true)
                        break;
                    case "update":
                        this.updateView(res.data, false)
                        break;
                    case "window_hide":
                        aform.fields.window_hide(res.data);
                        this.setFadeIn("parent,child,windows")
                        break;
                    case "window_show":
                        //enable = false;
                        aform.fields.window_show(res.data);
                        this.setFadeIn("windows")
                        break;
                    case "end_of_req":
                        //alert( "eor" );
                        dbg(2, "enable: " + enable + ", queuelen: " + rpc.RpcQueue.length)
                        if (enable && rpc.RpcQueue.length == 0) {
                            //alert( "enabling" )
                            dbg(2, "Fading in")
                            this.parentFadeIn();
                        }
                        break;
                    default:
                        alert("Unknown command: " + res.cmd)
                        break;
                }
            }

            if (this.form) {
                dbg(5, "setting updating on false in " + this.form);
                this.form.fields.updating = false;
            }
            dbg(5, "finished dispatcher");
        },

        setFadeIn: function (who) {
            this.selectfadein = who;
            if (this.parentLtab) {
                this.parentLtab.selectfadein = this.selectfadein
            }
        },

        autoUpdate: function (userData, timerId) {
            //alert( "in auto-update");
            dbg(3, "timer for update")
            var values = [];
            if (userData.replace(/^update(_async)*/, '') == "_with_values") {
                values = [this.form.fields.getFieldsData()];
                dbg(3, "Values are: " + print_a(values));
            }
            var dispatcher = this.dispatch_async;
            var async = false;
            if (userData.replace(/_with_values/, '') == "update") {
                this.parentFadeOut();
                dispatcher = this.dispatch
            } else {
                this.timer.pause();
                async = true
            }
            rpc.callRPCarray("View." + this.viewClass, userData,
                this, dispatcher, values, async);
        },

        parentFadeOut: function () {
            if (this.parentLtab) {
                this.parentLtab.parentFadeOut();
            } else {
                this.fadeOut();
                //this.timer.pause();

                var child = null;
                if (this.form && this.form.fields &&
                    ( child = this.form.fields.childLtab )) {
                    child.fadeOut();
                    child.timer.pause();
                }
            }
        },

        fadeOut: function () {
            if (!this.form || !this.form.fields) {
                return
            }
            dbg(5, "fading out windows");
            this.form.fields.windows_fade_to(0.5);
            if (!this.fadedin) {
                return
            }
            this.fadedin = false;
            this.form.fields.setEnabled(false);
            if (this.tabs) {
                this.tabs.setEnabled(false);
            }
            if (this.form.fields && this.form.fields.getContentElement() &&
                this.form.fields.getContentElement().getDomElement()) {
                // alert( "Doing fadout on " + this );
                this.fadeOut(0.25);
            }
        },

        parentFadeIn: function () {
            if (this.parentLtab) {
                this.parentLtab.parentFadeIn()
            } else {
                this.timer.cont();
                //alert( "fade_in is " + this.selectfadein + " for " + this )
                if (this.selectfadein.search("parent") >= 0) {
                    this.fadeIn();
                }
                var child = null;
                if (this.form && this.form.fields &&
                    this.form.fields.childLtab) {
                    child = this.form.fields.childLtab;
                    child.timer.cont();
                    if (this.selectfadein.search("child") >= 0) {
                        //alert( "fading in child " + child )
                        child.fadeIn();
                    } else {
                        //alert( "fading OUT child " + child )
                        child.fadeOut();
                    }
                }
                if (this.selectfadein.search("windows") >= 0) {
                    // Children are automatically faded, too
                    this.getActiveForm().fields.windows_fade_to(1);
                    //if ( child ){
                    //  child.getActiveForm().fields.windows_fade_to(1);
                    //}
                }
            }
        },

        fadeIn: function () {
            var aform = this.getActiveForm();
            this.enableThis();
            if (this.fadedin) {
                //alert( "already faded in " + this );
                return
            }
            //alert( "fading in " + this )
            this.fadedin = true;
            if (this.tabs) {
                this.tabs.setEnabled(true);
            }
            if (aform && aform.fields) {
                //alert( "Found aform" );
                //if ( aform.getContentElement().getDomElement() ){
                if (this.getContentElement().getDomElement()) {
                    //alert( "Doing fadin on layout " + aform );
                    this.fadeIn(0.25);
                }
            }
        },

        enableThis: function () {
            if (this.tabs) {
                //alert( "Enabling tabs " + this.tabs );
                this.tabs.setEnabled(true);
            }
            if (this.form && this.form.fields) {
                this.form.fields.setEnabled(true);
            }
            var aform = this.getActiveForm();
            if (aform && aform.fields) {
                aform.fields.setEnabled(true);
            }
        },

        setElementVisibility: function (el, vi) {
            var aform = this.getActiveForm();
            var f;
            if (f = aform.fields.fields[el]) {
                f.setVisibility(vi);
                if (f.widget_label) {
                    f.widget_label.setVisibility(vi);
                }
            } else {
                dbg(3, "Didn't find field " + el);
            }
        },

        // Displays the chosen view of the user
        showView: function (results) {
            this.layoutView = results.layout;
            this.dataClass = results.data_class;
            this.viewClass = results.view_class;
            dbg(5, "We have to show the following: " + this.layoutView);

            this.timer.stop();

            // Assure we're in the right tab
            if (this.tabs) {
                if (this.tabs.getSelection()[0].qv_id != this.viewClass) {
                    //alert("Changed tabs in the meantime: " +
                    //this.tabs.getSelection()[0].qv_id );
                    for (var v = 0; v < this.views.length; v++) {
                        if (this.views[v].qv_id == this.viewClass) {
                            this.tabs.setSelection([this.views[v]]);
                        }
                    }
                }
            }

            var container = this.getRootContainer();
            //alert( "container is " + container );
            dbg(5, "showView - container is: " + container);
            var cback = [this, this.dispatch];
            // dbg(5, "cback in showView is " + print_a(cback))
            if (!container.hasChildren()) {
                dbg(4, "Adding container " + this.viewClass);
                this.form = new frontend.Views.Form(cback, this.layoutView,
                    this.dataClass, this.viewClass, this);
                container.add(this.form);
                /*
                 if ( this.viewClass.search( /Tabs$/ ) >= 0 ){
                 // Sub-tabbed tabs get all the width
                 container.add( this.form );
                 } else {
                 container.add( this.form );
                 }
                 */
                this.form.fields.focus_if_ok(this.form.fields.first_field);
            }
            else {
                dbg(4, "Layout " + this.viewClass + " already here - doing nothing");
            }
        },
        updateView: function (results, silence) {
            dbg(4, "updateView: " + results)
            if (results) {
                this.form.fields.fill(results, silence);
            }
        },
        select: function (results, silence) {
            dbg(4, "select: " + results)
            if (results) {
                this.form.fields.unselect(results);
                this.form.fields.fill(results, silence);
            }
        },
        createViews: function (results) {
            var views = results.views
            dbg(5, "The following views are allowed: " + views);

            this.removeAll();

            this.tabs = new qx.ui.tabview.TabView(this.alignTabs).set("Enabled", false);

            this.views = [];
            for (var v = 0; v < views.length; v++) {
                dbg(2, "adding view-tab: " + views[v][0] + " - " + views[v][1]);
                this.views[v] = new qx.ui.tabview.Page(views[v][1]);
                this.views[v].qv_id = views[v][0]
                this.views[v].setLayout(new qx.ui.layout.Grow());
                var scroller = new qx.ui.container.Scroll();
                var composite = new qx.ui.container.Composite(new qx.ui.layout.Grow());
                //alert( "tab-cont is " + composite );
                scroller.add(composite);
                this.views[v].add(scroller);
                this.tabs.add(this.views[v]);
            }
            this.add(this.tabs);
            this.app.inflateCenter();
            dbg(3, "getRootContainer gives: " + this.getRootContainer());
            this.parentFadeOut();

            qx.event.Registration.addListener(this.tabs, "changeSelection", this.changeView, this);
            rpc.callRPC("View." + views[0][0], "show", this, this.dispatch);
            this.tabs.setSelection([this.views[0]]);
        },

        // Every time the view changes, this is called, which calls the Backend, which will call showView
        changeView: function (e) {
            this.timer.stop();
            if (this.form && this.form.fields.childLtab) {
                this.form.fields.childLtab.timer.stop();
            }
            var newView = e.getData()[0].qv_id;//.getSelection()[0];
            dbg(3, "New view is: " + newView)
            this.form = this.getActiveForm();
            var container = this.getRootContainer();
            var tabSel = this.tabs.getSelection()[0];
            //alert( "Disabling tabs " + this.tabs )
            this.tabs.setEnabled(false);
            var inTabs = "";
            var parentFields = null;
            if (this.parentLtab) {
                // We're in one of the sub-tabs, so let's send along the parent-
                // stuff
                dbg(3, "Adding something to the show - update_view");
                inTabs = "tabs_";
                parentFields = this.parentLtab.form.fields.getOwnFieldsData();
            } else {
                //alert( "resetting fadein")
                this.setFadeIn("parent,child,windows");
                if (this.form && this.form.fields) {
                    parentFields = this.form.fields.getOwnFieldsData();
                }
            }
            if (tabSel.initValues) {
                dbg(2, "initValue for " + tabSel);
                for (var i in tabSel.initValues) {
                    parentFields[i] = tabSel.initValues[i];
                }
                dbg(2, "parentFields is " + print_a(parentFields));
                tabSel.initValues = null;
            }
            this.parentFadeOut();
            if (!container.hasChildren()) {
                dbg(3, "changeView with data " + newView + " and field " + this.form);
                rpc.callRPC("View." + newView, inTabs + "show",
                    this, this.dispatch, parentFields);
            }
            else {
                dbg(3, "Tab already created - updating only - " + print_a(parentFields));
                this.viewClass = newView;
                rpc.callRPC("View." + newView, inTabs + "update_view",
                    this, this.dispatch, parentFields);
                // If there are kids, update them
                if (this.form.fields.childLtab) {
                    dbg(3, "Updating children");
                    if (this.form.fields.childLtab.form) {
                        var child = this.form.fields.childLtab;
                        var newView = child.tabs.getSelection()[0].qv_id;
                        var parentFields = this.form.fields.getOwnFieldsData();
                        rpc.callRPC("View." + newView, "tabs_update_view",
                            child, child.dispatch, parentFields);
                    }
                }
            }
        },

        // Helper function to get to the active form
        getActiveForm: function () {
            var base = this.getRootContainer();
            if (base.getChildren) {
                return base.getChildren()[0];
            }
            else {
                return null;
            }
        },
        getRootContainer: function () {
            dbg(5, "getActiveForm");
            return this.tabs ? this.tabs.getSelection()[0].getChildren()[0].getChildren()[0] :
                this;
        }
    }
});
