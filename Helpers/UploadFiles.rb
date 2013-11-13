# This works togehter with UploadMgr to retrieve files.
require 'cgi'

class UploadFiles < RPCQooxdooPath
  @@files = []
  def self.parse_req( req )
    dputs( 4 ){ "UploadFiles: #{req.inspect}" }
    path = get_config( '/tmp', :UploadFiles, :path )
    filename = CGI.unescape( req.header['x-file-name'][0] || "unknown" )
    filename = self.escape_chars( filename )
    dputs(4){"Writing to #{filename.inspect} in #{path.inspect}"}
    name = "#{path}/#{filename}"
    dputs(2){"Writing to #{name}"}
    File.open( "#{name}", "w:ASCII-8BIT" ){|f|
      f << req.query["file"]
    }
    @@files.push name
  end
  
  def self.get_files
    @@files
  end
  
  def self.escape_chars( name )
    name.gsub(/[^a-zA-Z0-9_\.-]/, '_')
  end
end