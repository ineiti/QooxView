/* ************************************************************************
 Copyright: 2010 by Linus Gasser
 License:	GPL v3
 Authors:	Linus Gasser
 ************************************************************************ */
/* ************************************************************************
 #asset(frontend/*)
 ************************************************************************ */
/**
 * Create the views in a Gestion-project
 */
qx.Class.define("frontend.Views.Form", {
    extend: qx.ui.container.Composite,
    
    /*
     * Constructor of Views.Create Takes:
     *
     */
    construct: function(cback, layout, dataClass, viewClass, rLayout){
        this.base(arguments, new qx.ui.layout.HBox());
        this.dataClass = dataClass;
        this.viewClass = viewClass;
        this.callback = cback;
        //dbg(3, "cback is: " + print_a(cback));
        this.add(this.fields = new frontend.Lib.Fields({
            callback: [this, this.changeId]
        }, layout, rLayout), {width: "100%", flex: 1} );
    },
    
    members: {
        // The parameters for this field-set
        dataClass: null,
        viewClass: null,
        callback: null,
        fields: null,
		effect: null,
		callback: null,
        
        /*
         * This is called whenever something changes. Appropriate actions are taken
         * from here with regards to the RPC-calls.
         */
        changeId: function(result){
            dbg(3, "Got changeId with " + print_a(result));
            dbg(5, "dataClass is " + this.dataClass);
            //dbg(5, "callBack is " + this.callBackend);
            var id = result[0];
            var name = result[1];
            var type = result[2];
            var value = result[3];
			var params = result[4];
            switch (type) {
                case "str":
				case "int":
				    this.fadeOut();
                    //this.fields.clearData();
					if (params.callback) {
						this.callBackend("callback", params.callback, this.fields.getFieldsData());
					} else {
						this.callBackend("find", name, value);
					}
                    break;
                case "button":
				    this.fadeOut();
                    this.callBackend("button", name, this.fields.getFieldsData());
                    break;
                case "list":
				    this.fadeOut();
                    this.callBackend("list_choice", name, this.fields.getFieldsData());
                    break;
                default:
                    this.fields.updating = false;
                    break;
            }
        },
		
		fadeOut: function(){
			this.fields.setEnabled( false );
			if ( this.fields && this.fields.getContainerElement() &&
			this.fields.getContainerElement().getDomElement() ){
				this.effect = new qx.fx.effect.core.Fade(this.fields.getContainerElement().getDomElement());
				this.effect.set( { from: 1, to: 0.5, duration: 0.25 });
				this.effect.start();
				this.fields.windows_fade_to( 0.5 );
	        }
		},
        
        // Adds all data in the arguments and calls the server
        callBackend: function(method){
            var args = [];
            for (var i = 1; i < arguments.length; i++) {
                args.push(arguments[i]);
            }
            dbg(5, "callBackend arguments are: " + args.join(":"));
            //dbg(5, "callback is: " + print_a(this.callback));
            rpc.callRPCarray("View." + this.viewClass, method, this.callback[0], this.callback[1], args);
        },
        
        // Small wrapper to correctly set the updating-flag
        newData: function(data){
            if (data) {
                this.fields.fill(data);
            }
            else {
                alert("This ID doesn't exist!");
            }
            this.fields.updating = false;
        },
        
        deleteData: function(result){
            if (result.answer == "OK") {
                alert("Deleted succesfully!");
            }
            else {
                alert("Couldn't delete because of " + result.reason);
            }
            this.fields.updating = false;
        },
        
        // Choses action to do if a button is pressed
        // IDEA: don't enable all fields when there is no ID present. Only enable
        // one field at a time and go directly to a search.
        handleButton: function(name){
            dbg(5, "handleButton for " + name)
            switch (name) {
                case "new":
                    this.fields.clearData();
                    this.callBackend("new_id", this, this.newData);
                    break;
                case "save":
                    this.callBackend("save", this, this.newData, this.fields.getFieldsData());
                    break;
                default:
                    this.callBackend("button", this, this.newData, name, this.fields.getFieldsData());
                    break;
            }
        }
    }
});
