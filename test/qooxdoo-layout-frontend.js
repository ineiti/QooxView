ret = [1,2,3];
alert( ret );
ret = ret.concat( [4,5] );
alert( ret );

// Create a button
var button1 = new qx.ui.form.Button("First Button", "icon/22/apps/internet-web-browser.png");

// Document is the application root
var doc = this.getRoot();

var layout = new qx.ui.container.Composite();
layout.setLayout( new qx.ui.layout.Canvas() );
doc.add( layout, {width: "80%"} );

var layout2 = new qx.ui.container.Composite();
layout2.setLayout( new qx.ui.layout.Canvas() );
layout.add( layout2, {width: "100%"} );

var tabview = new qx.ui.tabview.TabView();
layout2.add( tabview, {width:"100%"} );

var page = new qx.ui.tabview.Page();
page.setLayout( new qx.ui.layout.Canvas() );
tabview.add( page );

var scroll = new qx.ui.container.Scroll();
page.add( scroll, {width: "100%"} );

var comp = new qx.ui.container.Composite();
comp.setLayout( new qx.ui.layout.Canvas() );
scroll.add( comp );

var hbox = new qx.ui.container.Composite();
hbox.setLayout( new qx.ui.layout.HBox() );
comp.add( hbox, {width: "50%"} );

var comp2 = new qx.ui.container.Composite();
comp2.setLayout( new qx.ui.layout.VBox( 1 ) );
hbox.add( comp2, {width: "100%"} );

var comp3 = new qx.ui.container.Composite();
comp3.setLayout( new qx.ui.layout.VBox( 10 ) );
comp2.add( comp3 );

var group = new qx.ui.groupbox.GroupBox();
group.setLayout( new qx.ui.layout.VBox( 10 ) );
comp3.add( group );

