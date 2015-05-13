/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */


qx.Class.define("frontend.Lib.TimerF", {
  extend : qx.core.Object,

  construct : function() {
    this.timer = qx.util.TimerManager.getInstance();
  },

  members : {
    timer : null,
    timeout : null,
    callback : null,
    timerId : null,
    args : null,

    pause : function( ){
      
    },
    
    cb : function( ud, tid ){
      //alert( "Callback with a " + print_a( this.args ) );
      var a = this.args;
      a[0].call( a[2], a[3], tid )
    },
    
    cont : function(){
      var a = this.args;
      if ( a && a.length == 5 && ! this.timerId ){
        //alert( "Going for new timer " + a[1] + "-" + a[0] );
        this.timerId = 
        this.timer.start( this.cb, a[1], this, a[3], a[4] );        
      } else {
        //alert( "A is " + a + " print is " + print_a( a ) + " timer_id is " +
        //  this.timerId );
      }
    },

    start : function( callback, recurTime, context, userData, initialTime ){
      this.stop();
      this.args = [ callback, recurTime, context, userData, initialTime ];
      this.cont();
    },

    // Pause keeps the argument-list, and allows for a "cont"
    pause : function(){
      if ( this.timerId ){
        this.timer.stop( this.timerId );
        this.timerId = null;
      }      
    },
    
    // Stop deletes the argument-list, so a "cont" will do nothing
    stop : function(){
      this.pause();
      this.args = null;
    }
  }
} );