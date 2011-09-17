/* ************************************************************************

 Copyright: 2009 by Linus Gasser

 License:	GPL v3

 Authors:	Linus Gasser

 ************************************************************************ */

/* ************************************************************************

 ************************************************************************ */

/**
 * A fields-wrapper for working together with the RPC-part of
 * Qooxdoo
 */
qx.Class.define("frontend.Lib.RPC", {
	extend : qx.core.Object,

	construct : function() {
		this.rpc = new qx.io.remote.Rpc();
		// For debugging the ruby-thread in peace
		this.rpc.setTimeout(1000000);
		this.rpc.setCrossDomain(true);
		var url = document.URL.replace( /\/$/, '' ) + "/rpc";
		dbg( 3, "URL for RPC is " + url );
		this.rpc.setUrl(url);
		this.session_id = "default";
	},

	members : {
		rpc : null,
		session_id : null,
		RpcRunning : null,

		callRPCarray : function(service, method, obj, event, params) {
			if ( this.RpcRunning ){
				// alert( "Oops, RPC is running - going back" );
				return;
			}
			
			this.rpc.setServiceName(service);

			dbg(5, "Adding session_id " + this.session_id);
			params.unshift(this.session_id)
			var that = this;
			dbg(3, "Called RPC with "
					+ [ service, method, params.join(":") ].join("-"))
					
			// call a remote procedure -- takes no arguments, returns a string
			this.RpcRunning = this.rpc.callAsync(function(result, ex, id) {
				dbg( 3, "RpcRunning = null" );
				rpc.RpcRunning = null;
				if (ex == null) {
					//            alert( result.length + " - " + event );
					event.call(obj, result);
				} else {
					alert("Async(" + id + ") exception: " + ex);
				}
			}, method, params);
		},

		callRPC : function(service, method, obj, event) {
			var args = [];
			for ( var i = 4; i < arguments.length; i++) {
				args.push(arguments[i]);
			}

			this.callRPCarray(service, method, obj, event, args);

		}
	}
});
