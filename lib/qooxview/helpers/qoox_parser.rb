require 'rubygems'
require 'gettext'

include GetText

module QooxParser
  module_function
  # If the file is the target of your parser, then return true, otherwise false.
  def target?(file)
    File.extname(file) == ".rb"
  end

  def parse(file)
    ary = []
    File.open( file ){|f|
      line = 0
      f.readlines.each{|l|
        line += 1
        if l =~ /^\s*value_[^\s]+\s+[^=]/ or l =~ /^\s*show_[^\s]+\s+[^=]/ or
            l =~ /^\s*vtlp_list\s+[^=]/
          case l
          when /(value_block|show_block)/
          when /(show_button|show_print)/
            buttons = l.sub( /^[^:]*:/, '' ).gsub( /:/, '' ).chop.split( /,\s*/ )
            buttons.each{|b|
              po = POEntry.new(:normal)
              po.msgid = b
              po.references = [ "#{file}:#{line}" ]
              po.add_comment( "Comes from file #{file} and line is #{l}" )
              ary << po
            }
          else
            po = POEntry.new(:normal)
            po.msgid = l.sub( /^[^:]*:/, '' ).sub( /,.*/, '' ).chop
            po.references = [ "#{file}:#{line}" ]
            po.add_comment( "Comes from file #{file} and line is #{l}" )
            ary << po
          end
        elsif l =~ /<\s*View\s*$/
          po = POEntry.new(:normal)
          po.msgid = l.sub( /^\s*class\s*/, '' ).sub( /\s*<.*$/, '' ).chop
          po.references = [ "#{file}:#{line}" ]
          po.add_comment( "Comes from file #{file} and line is #{l}" )
          ary << po            
        end
      }
    }
    return ary
  end

end

# Add this parser to GetText::RGetText
GetText::Tools::XGetText.add_parser(QooxParser)
