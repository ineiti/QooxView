function print_a(a) {
  var res = "[";
  for (i in a) {
    if (a[i] && a[i].pop) {
      res += i + ":" + print_a(a[i]) + " - ";
    } else {
      res += i + ":" + a[i] + " - ";
    }
  }
  return res + " ]";
};

function dbg(lvl, str) {
  if (lvl <= DBG_LVL) {
    qx.log.Logger.info(str)
  }
};

String.prototype.repeat = function( num ) {
  for( var i = 0, buf = ""; i < num; i++ ) buf += this;
  return buf;
};

String.prototype.ljust = function( width, padding ) {
  padding = padding || " ";
  padding = padding.substr( 0, 1 );
  if( this.length < width )
    return this + padding.repeat( width - this.length );
  else
    return this;
}
String.prototype.rjust = function( width, padding ) {
  padding = padding || " ";
  padding = padding.substr( 0, 1 );
  if( this.length < width )
    return padding.repeat( width - this.length ) + this;
  else
    return this;
}
String.prototype.center = function( width, padding ) {
  padding = padding || " ";
  padding = padding.substr( 0, 1 );
  if( this.length < width ) {
    var len = width - this.length;
    var remain = ( len % 2 == 0 ) ? "" : padding;
    var pads = padding.repeat( parseInt( len / 2 ) );
    return pads + this + pads + remain;
  }
  else
    return this;
}