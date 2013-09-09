/* ************************************************************************
 Copyright: 2009 by Linus Gasser
 License:	GPL v3
 Authors:	Linus Gasser
 ************************************************************************ */
/* ************************************************************************
 #asset(frontend/*)
 ************************************************************************ */
function searchLabel(name){
  var selectables = this.getSelectables();
  for (var s = 0; s < selectables.length; s++) {
    var item = selectables[s];
    if (item.getLabel() == name) {
      this.setSelection([item]);
    }
  }
}

function searchIndex(id){
  this.setSelection([this.getSelectables()[id]]);
}

function selectedIndex(){
  var id = 0;
  var item = this.getSelection()[0];
  var items = this.getSelectables();
  for (var s = 0; s < items.length; s++) {
    if (items[s] == item) {
      return id;
    }
    id++;
  }
  return null;
}

function getValue(){
  return "hi";
}

function getValueList(){
  dbg(5, "getValueList");
  var ret = [];
  var selected = this.getSelection();
  for (var s = 0; s < selected.length; s++) {
    var sel = selected[s];
    if (this.valueIds) {
      ret.push(this.valueIds[this.indexOf(sel)]);
    }
    else {
      ret.push(sel.getLabel());
    }
  }
  return ret;
}

function getValueListArray(){
  dbg(5, "getValueListArray");
  var ret = [];
  var selectables = this.getSelectables();
  for (var s = 0; s < selectables.length; s++) {
    ret.push(selectables[s].getLabel());
  }
  return ret.concat(getValueList());
}

function setValueListCommon(values, list){
  dbg(5, "setValueList " + print_a( values ) );
  var selection = [];
  if (!values || !values.length ) {
    dbg( 5, "aborting setValueList");
    return;
  }
  for (var v = 0; v < values.length; v++) {
    var val = values[v];
    var item = null;
    dbg(5, "Adding value " + print_a(val))
    if (val instanceof Array) {
      // The first position is the internal id, the second is what to show
      dbg(5, "Value is an array!")
      if (!list.valueIds) {
        list.valueIds = [];
      }
      list.valueIds.push(val[0]);
      val = val[1];
    }
    //        else if ( val != null && val != "" ){
    else {
      if (list.valueIds) {
        item = list.getSelectables(true)[list.valueIds.indexOf(val)];
      }
      else {
        if ( list.findItem ){
          item = list.findItem(val);
        }
      }
    }
    if (item && ( ! list.nopreselect ) ) {
      selection.push(item);
      dbg(5, "Found a selection: " + val);
    }
    else
    if (val != "") {
      dbg(5, "Adding new item " + val)
      var item = new qx.ui.form.ListItem("" + val);
      list.add(item);
      if (list.valueIds && list.indexOf(item) != list.valueIds.length - 1) {
        alert("Different number of items in list and valueIds!");
      }
    }
  }
  list.setSelection(selection);
}

function setValueList(val){
  setValueListCommon(val, this);
}

function setValueDrop(val){
  dbg(5, "setValueDrop: " + print_a(val))
  if ( this.valueIds ){
    dbg( 3, "Having valueIds " + print_a( this.valueIds ) )
    setValueListCommon( val, this );
  } else 
  if (val.length == 1 && this.getChildren().length > 0) {
    var elements = this.getChildren();
    dbg(5, "Setting value of " + val + " to elements " + elements);
    for (var e = 0; e < elements.length; e++) {
      if (elements[e].getLabel() == val) {
        dbg(5, "Found element " + elements[e])
        this.setSelection([elements[e]]);
      }
    }
  }
  else {
    setValueListCommon( val, this );
  }
};

function setValueListArray(val){
  this.removeAll();
  setValueListCommon(val, this);
}

function setValueBold(val){
  this.valueBold = val
  text = val.split("\n").join("<br>")
  this.setValue( "<table bgcolor='ffffff'><tr><td><b>" + text + 
    "</b></td></tr></table>" )
}

function getValueBold(){
  return this.valueBold
}

/*
 field_element = new qx.ui.container.Composite(new qx.ui.layout.VBox(2));
 field_element.add(this.createDoW());
 var hours = new qx.ui.container.Composite(new qx.ui.layout.HBox(2));
 hours.add(this.createHours());
 hours.add(new qx.ui.basic.Label("-"));
 hours.add(this.createHours());
 field_element.add(hours);
*/
function getValueFromTo(){
  dbg(5, "getValueFromTo");
  var d = this.getChildren();
  var h = d[1].getChildren();
  var ret = [d[0].getSelection()[0].getLabel(), // days of blockage 
  h[0].getSelection()[0].getLabel(), // the from-hour 
  h[2].getSelection()[0].getLabel() // the to-hour 
  ];
  dbg(4, print_a(ret));
  return ret;
}

function setValueFromTo(){
}

function getValueDate(){
  return this.getDateFormat().format(this.getValue());
}

function setValueDate(v){
  this.setValue(this.getDateFormat().parse(v))
}

function twoDecimals(x){
  return x < 10 ? "0" + x : x;
}

function setValueArrayTable(val){
  //var val = [[1,2,3],[4,5,6]]
  //alert( "Setting val " + print_a( val ))
  var values = val;
  if ( val && ( val[0] instanceof Array ) && 
    ( val[0][1] instanceof Array ) ){
    this.valueIds = []
    for ( var i = 0; i < val.length; i++ ){
      this.valueIds.push( val[i][0] )
      values[i] = val[i][1]
    }
  } else {
    this.valueIds = null
  }
  //alert( "Setting data to " + print_a( values ) + 
  //  " - valueIds = " + print_a( this.valueIds) )
  this.getSelectionModel().resetSelection();
  this.getTableModel().setData(values)
}

function getValueTable(){
  var ret = [];
  var vids = this.valueIds;
  this.getSelectionModel().iterateSelection(function(ind) {
    if ( vids ){
      //alert( "getting valueIds of " + ( ind + 1 ) + " in " +
      //  print_a( vids ) )
      ret.push( vids[ind])
    } else {
      ret.push(ind);
    }
  });
  //alert( "Returning " + print_a( ret ) + " with valueIds of " +
  //  print_a( vids ) )
  return ret;
}
          
/**
* A fields-wrapper for working together with the RPC-part of Qooxdoo
*/
qx.Class.define("frontend.Lib.Fields", {
  extend: qx.ui.container.Composite,
    
  /*
 * Constructor of Lib.Fields
 * Takes:
 * - p : parameters to pass to the form, may be empty
 *  - NOTINUSE: rpc: method to call for the RPC-server whenever a request has to be made,
 *   may also be "" to show only a local form (like login and stuff)
 *  - write: groups that have the right to write in these fields, defaults
 *    to "all"
 *  - callback: function to call in case something has changed. This is an
 *     array of [ this, this.callback_function ], so that the appropriate
 *     environment can be recreated.
 * - f : array of fields to offer to the user. The syntax is:
 *     type:name:[label][:params]
 *     where type is one of the following, name is used for the array in
 *     "fields", label is shown where appliable, if empty is copied from
 *     name, params is used for some special fields
 *  - id_text: the id-field for this block, of type text
 *  - id_dropdown: the id-field for this block, of type dropdown
 *  - id_hidden: the id-field for this block, of type hidden
 *  - text: a single line of text
 *  - date: gets a date
 *  - tel: holds a telephone-number
 *  - select: takes a list of arguments to chose from, may include a comma-
 *    seperated list of values
 *  - button: shows a button
 *  - composite: offers a Composite-widget, to be filled in later
 *  - hidden: stores information but doesn't display
 *
 * Does:
 * - id-lookup: whenever the id-field is changed, it calls the RPC-method
 *  to get the data of the according id-field and fills the fields with that
 *  data
 * - changes to fields: if the user has the appropriate rights, all fields
 *  are changeable. If changes occur, the RPC-method is called with the new
 *  value for that field.
 *
 */
  construct: function(params, fields, rLayout){
    this.base(arguments, this.layout = new qx.ui.layout.Canvas());
    var ps = ["rpc", "write", "callback"];
    for (var p = 0; p < ps.length; p++) {
      var pa = ps[p];
      this[pa] = params[pa];
    }
    this.write = this.write ? this.write : "all";
    this.fields = [];
    this.windows = {};
    this.updating = false;
    this.field_id = null;
    this.needs_expansion = {};
    this.ltab = rLayout;
    dbg(5, "Writing is " + this.write + " our id is " + this);
    this.index = 1;
    this.timer = qx.util.TimerManager.getInstance();
    if (fields) {
      this.calcView(fields, this);
    }
  },
    
  members: {
    // The parameters for this field-set
    rpc: null,
    write: null,
    callback: null,
        
    field_id: null,
    fields: null,
    windows: null,
    first_field: null,
    /*
    first_button: null,
    first_button_window: null,
   */
    updating: null,
    index: null,
    timer: null,
    delayTimer: null,
    layout: null,
    childLtab: null, // an eventual sub-tab in our layout - only one possible
    ltab: null, // this is where we're attached to
    needs_expansion: null, // will be used to know whether we expand the first
    // group or not
        
    // Returns a map of all data in the Field
    getOwnFieldsData: function(){
      dbg(5, "getFieldsData");
      var result = {};
      for (var f in this.fields) {
        dbg(5, "Looking at field " + f)
        var field = this.fields[f]
        if (field.getValueSpecial) {
          dbg(5, "has getValueSpecial");
          if (field.getValueSpecial()) {
            result[f] = field.getValueSpecial();
            dbg(5, "Field " + f + " is of special-value " + result[f]);
          }
        }
        else 
        if (field.getValue) {
          dbg(5, "has getValue");
          if (field.getValue) {
            result[f] = field.getValue();
            dbg(5, "Field " + f + " is of value " + result[f]);
          }
        }
      }
      dbg(4, "getFieldsData: " + print_a(result));
      return result;
    },
         
    // Gets also parent and child data, if available 
    getFieldsData: function(){
      dbg( 5, "GetFieldsData" )
      var result = this.getOwnFieldsData();
      if ( this.childLtab && this.childLtab.form && this.childLtab.form.fields ){
        var otherData = this.childLtab.form.fields.getOwnFieldsData();
        for ( var res in otherData ){
          result[res] = otherData[res];
          dbg( 3, "got data for me: " + res + " = " + result[res] )
        }
      }
      if ( this.ltab.parentLtab ){
        var otherData = this.ltab.parentLtab.form.fields.getOwnFieldsData();
        for ( var res in otherData ){
          result[res] = otherData[res];
          dbg( 3, "got data for parent: " + res + " = " + result[res] )
        }
      }
      return result;
    },
        
    // Deletes all data given in "fields"
    clearDataOnly: function(fields){
      dbg(5, "clearDataOnly");
      this.updating = true;
      if (fields) {
        if ( ! ( fields instanceof Array ) ){
          fields = [ fields ]
        }
        dbg(5, "Deleting fields " + print_a(fields));
        for (var f = 0; f < fields.length; f++) {
          var field;
          if ( field = this.fields[fields[f]] ) {
            dbg(5, "Clearing field/list " + field);
            if ( field.valueIds ){
              field.valueIds = [];
            }
            if (field.removeAll && !field.getDateFormat) {
              field.resetSelection();
              field.removeAll();
            }
            else 
            if (field.resetValue) {
              field.resetValue();
            }
            else 
            if (field.setValueStr) {
              field.setValueStr("");
            }
            else 
            if (field.setValueArray) {
              field.setValueArray([]);
            }
            else 
            if (field.setValue) {
              field.setValue("");
            }
          }
        }
      }
      this.updating = false;
    },
        
    // Deletes all data in the fields
    clearData: function(lists){
      dbg(5, "clearData");
      var fields = [];
      for (var f in this.fields) {
        // We don't want lists to be cleaned, but date is a special case
        if (!this.fields[f].removeAll || this.fields[f].getDateFormat) {
          fields.push(f);
        }
      }
      dbg(5, "Clearing fields: " + print_a(fields));
      this.clearDataOnly(fields);
      this.clearDataOnly(lists);
    },
        
    clearDataAll: function(){
      dbg(5, "clearDataAll");
      var fields = [];
      for (var f in this.fields) {
        fields.push(f);
      }
      dbg(5, "Clearing fields: " + print_a(fields));
      this.clearDataOnly(fields);
    },
        
    // Fills data in the fields
    fill: function(data){
      dbg(3, "Filling with data " + print_a(data))
      for (var f in this.fields) {
        dbg(5, "Looking for data of field " + f);
        var field = this.fields[f]
        if (data[f] != null) {
          if (field.setValueStr) {
            dbg(4, "Setting str value of " + data[f] + " to field " + f);
            field.setValueStr(data[f].toString());
          }
          else 
          if (field.setValueArray) {
            dbg(4, "Setting array value of " + data[f] + " to field " + f);
            field.setValueArray(data[f]);
          }
          else 
          if (field.setValue) {
            dbg(4, "Setting normal value of " + data[f] + " to field " + f);
            field.setValue(data[f].toString());
          }
        }
      }
    },
        
    addElement: function(element, layout, index){
      dbg(5, "addElement called with " + [print_a(element), layout, index].join(":"))
      var type = element.shift();
      var name = element.shift();
      var label = element.shift();
      var params = element[0] ? element.shift() : [];
      var field_element = null;
      var show_label = true;
      var listener = "changeValue";
      var do_callback = false;
      var enter_klicks = true;
      var delay = 0;
      var button_default = null;
      dbg(5, "addElement " + type + " - " + label + " - " + print_a(params));
      switch (type) {
        // TODO: differenciate the different types
        case "str":
        case "tel":
        case "array":
        case "int":
          field_element = new qx.ui.form.TextField("");
          if (params.id || params.callback) {
            do_callback = true;
            listener = "input";
            if (params.id) {
              this.field_id = name;
            }
            delay = 1500;
          }
          if (params.ro) {
            field_element = new qx.ui.basic.Label("");
            field_element.setRich( true )
            field_element.setWrap( true )
            field_element.setValueStr = setValueBold
            field_element.getValueSpecial = getValueBold
          //field_element.setValueStr( "-" )
          //field_element.setReadOnly(true);
          }
          if (type == "int") {
            field_element.setTextAlign("right");
          }
          break;
        case "text":
          field_element = new qx.ui.form.TextArea("");
          field_element.setAutoSize(true);
          field_element.setWidth(300);
          enter_klicks = false;
          if (params.ro) {
            field_element.setReadOnly(true);
          }
          if (params.ro) {
            field_element = new qx.ui.basic.Label("");
            field_element.setRich( true )
            field_element.setValueStr = setValueBold
            field_element.getValueSpecial = getValueBold
          //field_element.setValueStr( "-" )
          //field_element.setReadOnly(true);
          }
          break;
        case "date":
          field_element = new qx.ui.form.DateField();
          field_element.setDateFormat(new qx.util.format.DateFormat("dd.MM.yyyy"));
          field_element.getValueSpecial = getValueDate;
          field_element.setValueStr = setValueDate;
          break;
        case "info":
          //field_element = new qx.ui.form.TextField(params.text);
          //field_element.setReadOnly(true);
          
          field_element = new qx.ui.basic.Label(params.text);
          field_element.setRich( true )
          field_element.setWrap( true )
          field_element.setValueStr = setValueBold
          field_element.getValueSpecial = getValueBold

          break;
        case "pass":
          field_element = new qx.ui.form.PasswordField("");
          break;
        case "button":
          do_callback = true;
          listener = "execute";
          field_element = new qx.ui.form.Button(label);
          field_element.getData = function(){};
          field_element.setAllowGrowY( false );
          show_label = false;
          if (!button_default || params.def) {
            button_default = field_element;
            for ( var i in this.fields ){
              if ( ! this.fields[i].button_default ){
                this.fields[i].button_default = button_default;
              }
            }
          }
          break;
        case "split_button":
          do_callback = true;
          listener = "execute";
          field_element = new qx.ui.form.SplitButton(label);

          field_element.getData = function(){};
          field_element.setAllowGrowY( false );
          field_element.setValueArray = function(l){
            var fe = this;
            if ( typeof(l) === "string" ){
              fe.setLabel(l)
            } else 
            if ( l.length > 0 ){
              fe.setLabel(l.shift())
              var menu = new qx.ui.menu.Menu;
              for( var i=0; i<l.length; i++ ){
                var n = l[i]
                var b = new qx.ui.menu.Button(n);
                b.addListener("execute", function(e){
                  fe.fireDataEvent("execute", this.getLabel() )
                }, b )
                menu.add( b );
              }
              fe.setMenu( menu );
            }
          }
          field_element.setValueArray([label].concat( params.menu ) )
          show_label = false;
          if (!button_default || params.def) {
            button_default = field_element;
            for ( var i in this.fields ){
              if ( ! this.fields[i].button_default ){
                this.fields[i].button_default = button_default;
              }
            }
          }
          break;
        case "html":
          //	field_element = new qx.ui.embed.Html( element.replace(/^html:/, '') );
          field_element = new qx.ui.basic.Label().set({
            value: params.text,
            rich: true,
            allowGrowX: true
          });
          // field_element.set( {height: 100})
          show_label = false;
          break;
        case "select":
          field_element = new qx.ui.form.SelectBox();
          // There are labels to put in the select-box
          if (params.list_values) {
            while (params.list_values.length > 0) {
              field_element.add(new qx.ui.form.ListItem(params.list_values.shift()));
            }
          }
          field_element.searchLabel = searchLabel;
          field_element.searchIndex = searchIndex;
          field_element.selectedIndex = selectedIndex;
          listener = "changeSelection";
          break;
        case "list":
          if (params.list_type != "drop") {
            field_element = new qx.ui.form.List();
            field_element.setSelectionMode(params.list_type ? "single" : "additive");
            if ( ! params.flexheight ){
              //field_element.setMaxHeight(250);             
              field_element.setMaxHeight(250);
              field_element.setAllowGrowX(true);
              field_element.setAllowStretchX(true);
              field_element.setAllowGrowY(true);
              field_element.setAllowStretchY(true);
            }else{
              //field_element.setMinHeight(250);
            //alert( "flexheight" )
            }
            field_element.setMinWidth(200);
            if ( params.nopreselect ){
              field_element.nopreselect = true
            }
          }
          else {
            field_element = new qx.ui.form.SelectBox();
          }
          field_element.searchLabel = searchLabel;
          field_element.searchIndex = searchIndex;
          field_element.selectedIndex = selectedIndex;
          if (params.list_type == "array") {
            field_element.setValueArray = setValueListArray;
            field_element.getValue = getValueListArray;
          }
          else 
          if (params.list_type != "drop") {
            field_element.setValueArray = setValueList;
            field_element.getValue = getValueList;
          }
          else {
            field_element.setValueArray = setValueDrop;
            field_element.getValue = getValueList;
          }
          if (params.ro) {
            field_element.setEnabled(false)
          }
          field_element.setValueArray(params.list_values);
                    
          //field_element.setHeight(null);
          //field_element.setMaxHeight( 100 );
          listener = "changeSelection";
          if (params.callback) {
            do_callback = true;
          }
          break;
        case "composite":
          field_element = new qx.ui.container.Composite();
          show_label = false;
          listener = null;
          break;
        case "table":
          var headings = params.headings;
          var tableModel = new qx.ui.table.model.Simple();
          var height = params.height || 250;
          var widths = params.widths;
          tableModel.setColumns(headings);
          
          var table = new qx.ui.table.Table(tableModel).set({
            decorator: null,
            showCellFocusIndicator: false
          });
          table.getSelectionModel().setSelectionMode(
            qx.ui.table.selection.Model.MULTIPLE_INTERVAL_SELECTION_TOGGLE);
          table.setValueArray = setValueArrayTable;
          table.getValue = getValueTable;
          table.setStatusBarVisible(false);
          table.setAllowShrinkY( true );
          table.setAllowStretchY( true );
          table.setMaxHeight(height);
          if ( widths ){
            for ( var i = 0; i < widths.length; i++ ){
              table.setColumnWidth( i, widths[i] );
            }
          }
          //field_element = new qx.ui.container.Scroll();
          //field_element.add( table );
          field_element = table;
          show_label = false;
          listener = "dataEdited";
          //params.flexheight = 1;
          break;
        case "hidden":
          this.fields[name] = new qx.ui.basic.Label(params);
          if (params.id) {
            this.field_id = name;
          }
          break;
        case "fromto":
          field_element = new qx.ui.container.Composite(new qx.ui.layout.VBox(2));
          field_element.add(this.createDoW());
          var hours = new qx.ui.container.Composite(new qx.ui.layout.HBox(2));
          hours.add(this.createHours());
          hours.add(new qx.ui.basic.Label("-"));
          hours.add(this.createHours());
          field_element.add(hours);
          field_element.getValue = getValueFromTo;
          field_element.setValueStr = setValueFromTo;
          break;
        case "upload":
          show_label = false;
          var do_callback = [ params.callback, this.callback ]
          field_element = new qx.ui.container.Composite(new qx.ui.layout.HBox(2));
          var button = new com.zenesis.qx.upload.UploadButton(label);
          field_element.add(button);
          var progress = new qx.ui.container.Composite(new qx.ui.layout.VBox(2));
          var pb = new qx.ui.indicator.ProgressBar(0, 100);
          var pb_color_orig = pb.getBackgroundColor();
          progress.add( pb );
          var progress_label = new qx.ui.basic.Label("No file");
          progress.add( progress_label );
          field_element.add( progress );
          field_element.progress = [ pb, progress_label ]
          field_element.setValue = function(){
            //alert("Setting value" );
            pb.setBackgroundColor("#ffffff");
            pb.setValue( 0 );
            progress_label.setValue( "No file" );
          }

          var uploader = new com.zenesis.qx.upload.UploadMgr(button, "/uploadfiles");
          uploader.addListener("addFile", function(evt) {
            var file = evt.getData();
            var start = (new Date).getTime();
            var progressListenerId = file.addListener("changeProgress", function(evt) {
              var value = Math.round(evt.getData() / file.getSize() * 100)
              //alert("New value for progressbar " + pb + ": " + value)
              pb.setValue( value );
              var diff = ( (new Date).getTime() - start ) / 1000;
              var elapsed = Math.round( diff ) + "s"
              var speed = Math.round( evt.getData() / diff / 1000 ) + "kBps"
              if ( value < 100 ){
                progress_label.setValue( "Done " + value.toString().rjust(3, "0") +
                  "% in " + elapsed + " (" + speed + "), " +
                  " left: " + ( Math.round( 0.8 + diff * ( 100 / value - 1 ) ) ) );
              } else {
                progress_label.setValue( "Waiting for browser" );
              }
            }, this);
          
            // All browsers can at least get changes in state (ie "uploading", "cancelled", and "uploaded")
            var stateListenerId = file.addListener("changeState", function(evt) {
              var state = evt.getData();
      				
              if (state == "uploading"){
                pb.setBackgroundColor("#f55");
                progress_label.setValue( "Started upload" )
              } else if (state == "uploaded"){
                pb.setValue( 100 );
                pb.setBackgroundColor("#5f5");
                progress_label.setValue( "Finished" )
              }		
              if (state == "uploaded" || state == "cancelled") {
                file.removeListenerById(stateListenerId);
                file.removeListenerById(progressListenerId);
                if ( do_callback[0] ){
                  do_callback[1][1].call(do_callback[1][0],
                    [0, name, "upload", file.getFilename(), 0])
                }
              }
      				
            }, this);
          } );
          break;
        default:
          alert("This shouldn't happen! Asked for element " + type);
          break;
      }
            
      // Get the field_element in place, adding the listener if necessary
      if ( field_element && ! params.hidden ) {
        dbg(5, "Adding: " + type + ":" + name + ":" + label + " to " + layout.getLayout());
        this.fields[name] = field_element;
        this.fields[name].field_name = name; 
        field_element.setTabIndex(this.index++);
        if (!this.first_field) {
          this.first_field = field_element;
        }
        if ( type != "button" ){
          button_default = null;
        }
        field_element.addListener("keypress", function(e){
          if (e.getKeyIdentifier() == "Enter" && enter_klicks) {
            dbg(5, "This is Enter for " + e + ":" + name + ":" + label);
            if (this.button_default) {
              this.button_default.execute();
            }
          }
        }, field_element );
        if ( params.width ){
          field_element.setMinWidth(params.width);
        }
                
        if (show_label) {
          var widget_label = new qx.ui.basic.Label(label);
          widget_label.setBuddy(field_element);
          layout.add(widget_label, {
            row: index,
            column: 0
          });
          field_element.widget_label = widget_label;
        }
        if (/Grid/.test(layout.getLayout().toString())) {
          layout.add(field_element, {
            row: index,
            column: 1
          });
          if ( params.flexheight ){
            dbg( 3, "Setting rowflex to " + params.flexheight )
            layout.getLayout().setRowFlex( index, params.flexheight );
            if ( params.flexheight > 0){
              this.needs_expansion.height = "100%";
            }
          }
        }
        else {
          dbg(5, "Adding without VBox: " + field_element + " to " + layout.getLayout().toString());
          layout.add(field_element, {
            flex: 1
          });
        }
        // Add a handler for automatically reporting changing values
        if (listener/* && this.rpc */ && this.callback && do_callback) {
          dbg(4, "Adding listener: " + type + ":" + name + ":");
          if ( typeof( listener ) === "string" ){
            listener = [listener]
          }
          for ( var l=0; l<listener.length; l++ ){
            field_element.addListener(listener[l], function(e){
              //alert( "Listener " + name + ":" + e )
              // Supposing Javascript has only one executable thread!
              if (!this.updating || (delay > 0 && this.delayTimer)) {
                dbg(5, "Listener: " + type + ":" + name + ":" + this.field_id);
                this.updating = true;
                            
                var id = null;
                if (this.field_id) {
                  this.fields[this.field_id].getValue();
                }
                            
                // Some elements don't have any data (like buttons)
                var data = e.getData ? e.getData() : "";
                // Have a delay for some actions that might take time
                if (delay == 0) {
                  //dbg( 3, "Callback is " + print_a( this.callback ) )
                  this.callback[1].call(this.callback[0], [id, name, type, data, params])
                }
                else {
                  if (this.delayTimer) {
                    dbg(4, "Stopping timer");
                    this.timer.stop(this.delayTimer);
                    this.delayTimer = null;
                  }
                  dbg(4, "Adding new timer");
                  this.delayTimer = this.timer.start(function(userData, timerId){
                    dbg(3, "timer for delay")
                    this.callback[1].call(this.callback[0], [id, name, type, data, params])
                  }, 0, this, null, delay);
                }
              }
              else {
                dbg(3, "Can't call listener while he's working!");
              }
            }, this);
            dbg(5, "Finished adding listener " + listener[l])
          }
        }
      }
      return field_element;
    },
        
    // Creates the view for the layout-array provided. The
    // array consists of
    // strings readable by the Lib.Fields-class, plus these
    // extensions:
    // - vbox - creates a vertical box
    // - hbox - creates a horizontal box
    // - fields_layout - prepares for a common block
    // - fields_noflex - prepares for a common block
    // - group - a group-box
    // - window - a popup-window, hidden by default
    // - tab - a tab-in-tab presentation
    //
    // The format is
    // [ 'extension', [ fields-string, [ 'extension', [
    // fields-string, ... ] ], ... ] ]
    calcView: function(view_str, lyt){
      // dbg(5, "calcView: " + print_a(view_str) + ":" + lyt);
      var flexit = 1;
      if (view_str[0] && view_str[0].split) {
        var args = view_str[0].split(":");
        switch (args[0]) {
          case "fields_layout":
            dbg(5, "Adding a fields_layout to " + lyt + " - " + print_a(view_str[1]));
            //lyt.add( 
            this.calcView(view_str[1], new qx.ui.container.Composite(new qx.ui.layout.HBox(10)));
            //, {
            //    colSpan : 2
            //});
            break;
          case "fields_noflex":
            dbg(4, "fields_noflex");
            flexit = 0;
          case "fields":
            dbg(5, "Adding some fields to " + lyt);
            var layout = lyt.add(this.calcView(view_str[1], new qx.ui.container.Composite(new qx.ui.layout.Grid().setColumnAlign(0, "right", "middle").setSpacing(5).setColumnFlex(0, flexit).setColumnFlex(1, 1))), {
              flex: 1
            });
            break;
          case "group":
            dbg(5, "Adding a group to " + lyt);
            if ( ! this.first_group ){
              this.first_group = lyt;
            }
            var gb = new qx.ui.groupbox.GroupBox();
            gb.setLayout(new qx.ui.layout.VBox(10));
            if ( false ){
              lyt.add(this.calcView(view_str[1], gb) );
            } else {
              if ( lyt.getLayout().constructor != qx.ui.layout.Canvas ){
                dbg( 3, "Adding with flex" );
                lyt.add(this.calcView(view_str[1], gb), {
                  flex: 1
                });
              } else {
                dbg( 3, "Adding for canvas" );
                var sub_layout = this.calcView(view_str[1], gb);
                //alert( "needs_expansion.height is " + this.needs_expansion.height );
                lyt.add( sub_layout, this.needs_expansion );
              }
            }
            break;
          case "groupw":
            dbg(5, "Adding a group to " + lyt);
            var gb = new qx.ui.groupbox.GroupBox();
            gb.setLayout(new qx.ui.layout.VBox(10));
            if ( false ){
              lyt.add(this.calcView(view_str[1], gb) );
            } else {
              if ( lyt.getLayout().constructor != qx.ui.layout.Canvas ){
                dbg( 3, "Adding with flex" );
                lyt.add(this.calcView(view_str[1], gb), {
                  flex: 1
                });
              } else {
                dbg( 3, "Adding for canvas" );
                lyt.add(this.calcView(view_str[1], gb),
                {
                  height: "100%",
                  width: "100%"
                });
              }
            }
            break;
          case "hbox":
            dbg(5, "Adding a hbox to " + lyt);
            var hbox = new qx.ui.layout.HBox(10);
            var container = new qx.ui.container.Composite( hbox );
            var opts = this.needs_expansion.height;
            var sub_layout = this.calcView(view_str[1], container);
            if ( opts != this.needs_expansion.height ){
              opts = { flex: 1 };
            } else {
              opts = {};
            }
            lyt.add( sub_layout, opts );
            break;
          case "hboxg":
            dbg(5, "Adding a hbox to " + lyt);
            var hbox = new qx.ui.layout.HBox(10);
            var container = new qx.ui.container.Composite( hbox );
            lyt.add(this.calcView(view_str[1], container), {
              flex: 1
            });
            break;
          case "shrink":
            dbg(5, "Adding a shrink-group to " + lyt);
            var gb = new qx.ui.groupbox.GroupBox();
            gb.setLayout(new qx.ui.layout.VBox(10));
            lyt.add(this.calcView(view_str[1], gb));
            break;
          case "tabs":
            var tabsName = view_str[1][0][0];
            dbg( 3, "Adding new tabs " + print_a( view_str ) + "::" + tabsName);
            this.childLtab = new frontend.Views.Ltab( this.ltab.app );
            this.childLtab.alignTabs = "top";
            this.childLtab.parentLtab = this.ltab;
            var container = new qx.ui.container.Composite(new qx.ui.layout.Grow());
            container.add( this.childLtab );
            lyt.add( container, {
              flex: 5
            } );
            rpc.callRPC("View." + tabsName, "list_tabs", this.childLtab, this.childLtab.dispatch);
            break;
          case "vbox":
            dbg(5, "Adding a vbox to " + lyt);
            var layout = new qx.ui.container.Composite(new qx.ui.layout.VBox(10).set({
              alignX: "right"
            }));
            var opts = this.needs_expansion.height;
            var sub_layout = this.calcView(view_str[1], layout );
            if ( opts != this.needs_expansion.height ){
              opts = { flex: 1 };
            } else {
              opts = {};
            }
            lyt.add( sub_layout, opts );
            break;
          case "vboxg":
            dbg(5, "Adding a vboxg to " + lyt);
            var layout = new qx.ui.container.Composite(new qx.ui.layout.VBox(10).set({
              alignX: "right"
            }));
            lyt.add(this.calcView(view_str[1], layout ), {
              flex: 1
            });
            break;
          case "vboxgl":
            dbg(5, "Adding a vboxgl to " + lyt);
            var layout = new qx.ui.container.Composite(new qx.ui.layout.VBox(10).set({
              alignX: "right"
            }));
            /*var container = new qx.ui.container.Composite(new qx.ui.layout.Canvas());
            container.add( this.calcView(view_str[1], layout ), {
              width: "100%", 
              height: "100%"
            } );*/
            lyt.add( this.calcView(view_str[1], layout ), {
              flex: 1
            } );
            break;
          case "window":
            dbg(5, "Adding a window with layout " + view_str[1] );
            var old_field = this.first_field;
            this.first_field = null;
            /*
            var old_button = this.first_button;
            this.first_button = null;
           */
            var l = new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
            this.calcView(view_str[1], l);
            var win = new qx.ui.window.Window("Window").set({
              modal: true,
              allowClose: false,
              visibility: "hidden"
            });
            win.setLayout(new qx.ui.layout.HBox());
            win.add(l);
            win.layout = l;
            win.center();
            win.created = false;
            win.dontfade = false;
            win.isfaded = 1;
            win.first_field = this.first_field;
            this.first_field = old_field;
            this.windows[args[1]] = win;
            win.addListenerOnce('appear',function(){
              win.created = true;
            } );
            /*
            win.first_button = this.first_button;
            this.first_button = old_button;
           */

            break;
        }
      }
      else {
        dbg(5, "Adding elements to " + lyt);
        var elements = view_str;
        for (var l = 0; l < elements.length; l++) {
          // Testing if we have another array
          if (elements[l].push && elements[l].length < 4) {
            dbg(5, "Adding composite: " + elements[l] + " with " + lyt);
            var newlyt = this.calcView(elements[l], lyt);
          }
          else {
            dbg(5, "Creating element with fields " + elements[l] + " on layout " + lyt);
            this.addElement(elements[l], lyt, parseInt(l));
          }
        }
      }
      dbg(5, "returning from calcView, string is: " + view_str[0])
      return lyt;
    },
        
    // Gives focus but tests first
    focus_if_ok: function( field ){
      if (field && field.isFocusable()) {
        dbg(4, "Focusing on " + field);
        field.focus();
      }        	
    },
        
    // Put a window into visibility, hiding the background
    window_show: function(name){
      dbg(2, "Showing window " + name);
      win = this.windows[name];
      win.setVisibility("visible");
      win.focus();
      win.activate();
      win.dontfade = false;
      this.window_fade_to( win, 1 );
      this.focus_if_ok( win.first_field )
    /*
      this.first_button_window = this.first_button;
      this.first_button = win.first_button;
     */
    //this.windows_fade_to( 1 );
    },
    
    window_fade_to: function( win, target ){
      if ( win.created && ! win.dontfade && win.isfaded != target ){
        win.isfaded = target;
        //alert( "Fading " + win + " to " + target )
        var effect = new qx.fx.effect.core.Fade(
          win.layout.getContainerElement().getDomElement());
        //this.windows[w].layout.getContainerElement().getDomElement());
        effect.set({
          from: 1.5 - target,
          to: target,
          duration: 0.25
        });
        effect.start();
        win.setEnabled( target < 1 ? false : true );
      } else {
      //alert( "Trying to fade window " + w + " which is not created yet")
      }
    },
        
    windows_fade_to: function( target ){
      //return;
      //alert( "fading windows " + print_a( this.windows ) + " to " + target );
      for ( var w in this.windows ){
        //alert( "fading windows " + w + " to " + target );
        this.window_fade_to( this.windows[w], target );
      }
      if ( this.childLtab && this.childLtab.form && this.childLtab.form.fields ){
        this.childLtab.form.fields.windows_fade_to( target );
      }
    },
        
    window_hide: function(name){
      dbg(2, "Hiding window " + name + " of " + this.windows.length);
      if (name == "*" || !name) {
        for (var i in this.windows) {
          dbg( 2, "Hiding window " + i);
          this.windows[i].setVisibility("hidden");
          this.windows[i].dontfade = true;
        }
      }
      else {
        this.windows[name].setVisibility("hidden");
      }
      /*
      if ( this.first_button_window ){
        this.first_button = this.first_button_window;
        this.first_button_window = null;
      }
     */
      this.focus_if_ok( this.first_field );
    },
        
    createHours: function(){
      var selectBox = new qx.ui.form.SelectBox();
      for (var i = 0; i < 48; i++) {
        var tempItem = new qx.ui.form.ListItem("" +
          twoDecimals(Math.floor(i / 2)) +
          ":" +
          twoDecimals((i % 2) * 30));
        selectBox.add(tempItem);
      }
      selectBox.setWidth(null);
      return selectBox;
    },
        
    createDoW: function(){
      var selectBox = new qx.ui.form.SelectBox();
      var items = ['lu-ve', 'lu-di', 'sa-di', 
      'lu', 'ma', 'me', 'je', 've', 'sa', 'di', 
      'lu:me:ve', 'ma:je:sa'];
      for (var i = 0; i < items.length; i++) {
        var tempItem = new qx.ui.form.ListItem(items[i]);
        selectBox.add(tempItem);
      }
      selectBox.setWidth(null);
      return selectBox;
    }
  } // members
});
