=begin
 Offers simple OpenOffice-find/replace stuff and printing 
=end

require 'rubygems'
require 'docsplit'
require 'zip/zipfilesystem'; include Zip

class OpenPrint
  def initialize( file, dir = nil )
    @file = file
    @dir = dir
    @base = `basename #{file}`
    if $config[:default_printer]
      @default_printer = "-P #{$config[:default_printer]}"
    else
      @default_printer = nil
    end
    @counter = 0
  end
  
  def print( fields, counter = nil, name = nil )
    dputs( 3 ){ "New print for #{@file}" }
    if name
      tmp_file = "/tmp/#{name}.#{@base.sub(/.*\./,'')}"
    else
      counter ||= @counter
      tmp_file = "/tmp/#{counter}-#{@base}"
      @counter += 1
    end
    pdf_file = tmp_file.sub(/[^\.]*$/, 'pdf')
    cmd = @default_printer ? "lpr #{@default_printer} #{pdf_file}" : nil

    FileUtils::cp( @file, tmp_file )
    ZipFile.open( tmp_file ){ |z|
      doc = z.read("content.xml")
      fields.each{|f|
        doc.gsub!( f[0], f[1].to_s )
      }
      z.file.open("content.xml", "w"){ |f|
        f.write( doc )       
      }
      z.commit
    }

    Docsplit.extract_pdf tmp_file, :output => "/tmp"
    #FileUtils::cp( tmp_file, pdf_file )
    dputs( 5 ){ "Finished docsplit" }
    @dir and FileUtils::cp( pdf_file, @dir )
    #    FileUtils::rm( tmp_file )
    if cmd
      dputs( 0 ){ cmd }
      `#{cmd}`
      return true
    else
      # Download PDF
      return "#{pdf_file}"
    end
  end
end

module PrintButton
  def get_remote_printers(ip)
    ddputs(4){"Getting printers for #{ip}"}
    %x( lpstat -h #{ip}:631 -a | sed -e "s/ .*//" ).split
  end
  
  def get_local_printers
    get_remote_printers("localhost")
  end
  
  def show_print( *buttons )
    ddputs(3){"show_print with #{buttons.inspect}"}
    if not instance_variable_defined? :@default_printer
      @default_printer = {}
    end
    print_name = nil
    gui_hbox :nogroup do
      buttons.to_a.each{|b|
        ddputs(4){"Doing #{b.inspect}"}
        if b.to_s =~ /^print/
          show_split_button b, get_local_printers
          print_name = b.to_sym
        else
          show_button b
        end
      }
      if not print_name
        show_split_button :print, get_local_printers
        print_name = :print
      end
      @default_printer[print_name] = 
        Entities.Statics.get(self.name.to_s + print_name.to_s)
      if @default_printer[print_name].data_str == ""
        @default_printer[print_name].data_str = get_local_printers.first
      end
    end
  end
  
  def reply_print(session)
    ret = []
    @default_printer.each{|k,v|
      ddputs(4){"#{k}-#{v.inspect}"}
      value = "#{GetText._( k.to_s )} #{v.data_str}"
      if ip = session.web_req.peeraddr[3]
        if not ip =~ /(::1|localhost|127.0.0.1)/
          value = [ value ] + get_local_printers + get_remote_printers(ip)
        end
      end
      ret += reply( :update, k => value )
    }
    ddputs(4){"#{ret.inspect}"}
    ret
  end
  
  def get_printer( name )
    @default_printer[name.to_sym].data_str
  end
  
  def rpc_print( session, name, data )
    ddputs(4){"Printing button #{name} with #{data.inspect}"}
    if data['menu'] and data['menu'].length > 0
      @default_printer[name.to_sym].data_str = data['menu']
    end
    reply_print( session )
  end
end