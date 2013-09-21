=begin
 Offers simple OpenOffice-find/replace stuff and printing 
=end

require 'rubygems'
require 'docsplit'
#require 'zip/zipfilesystem'; include Zip
require 'zip'

class OpenPrint
  attr_accessor :lp_cmd
  
  def initialize( file, dir = nil )
    @file = file
    @dir = dir
    @base = `basename #{file}`.chomp
    @lp_cmd = nil
    @counter = 0
  end
  
  def replace_accents( str )
    str = str.downcase.gsub( / /, "_" )
    accents = Hash[ *%w( a àáâä e éèêë i ìíîï o òóôöœ u ùúûü c ç ss ß )]
    dputs( 4 ){ "str was #{str}" }
    accents.each{|k,v|
      str.gsub!( /[#{v}]/, k )
    }
    str.gsub!( /[^a-z0-9_-]/, '_' )
    dputs( 4 ){ "str is #{str}" }
    str
  end
  
  def print( fields, counter = nil, name = nil )
    dputs( 3 ){ "New print for -#{@file.inspect}-" }
    if name
      tmp_file = "/tmp/#{replace_accents(name)}.#{@base.sub(/.*\./,'')}"
    else
      counter ||= @counter
      tmp_file = "/tmp/#{counter}-#{@base}"
      @counter += 1
    end
    pdf_file = tmp_file.sub(/[^\.]*$/, 'pdf')
    dputs(3){"Copying to -#{tmp_file.inspect}-"}

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

    if not get_config( false, :OpenPrint, :simulation )
      Docsplit.extract_pdf tmp_file, :output => "/tmp"
      #FileUtils::cp( tmp_file, pdf_file )
      dputs( 5 ){ "Finished docsplit" }
    else
      FileUtils::cp( tmp_file, pdf_file )
    end
    @dir and FileUtils::cp( pdf_file, @dir )
    #    FileUtils::rm( tmp_file )
    if @lp_cmd
      dputs( 0 ){ "Printing with --#{@lp_cmd} #{pdf_file}--" }
      `#{@lp_cmd} #{pdf_file}`
      return true
    else
      # Download PDF
      return "#{pdf_file}"
    end
  end
end

module PrintButton
  attr_reader :printer_buttons
  
  def call_lpstat(ip)
    %x( which lpstat >/dev/null 2>&1 && lpstat -h #{ip}:631 -a | sed -e "s/ .*//" ).split
  end
  
  def get_remote_printers(ip)
    if ip.match( get_config( "none", :OpenPrint, :search_remote ) )
      dputs(2){"Getting printers for #{ip}"}
      call_lpstat(ip)
    else
      dputs(2){"Not getting remote for #{ip}"}
      []
    end
  end
  
  def get_server_printers
    call_lpstat("localhost").collect{|p|
      "server #{p}"
    } + %w( PDF )
  end
  
  def show_print( *buttons )
    dputs(3){"show_print with #{buttons.inspect}"}
    if not instance_variable_defined? :@printer_buttons
      @printer_buttons = []
    end
    print_name = nil
    buttons.to_a.each{|b|
      dputs(4){"Doing #{b.inspect}"}
      if b.to_s =~ /^print/
        show_split_button b, get_server_printers
        print_name = b.to_sym
      else
        show_button b
      end
    }
    if not print_name
      show_split_button :print, get_server_printers
      print_name = :print
    end
    @printer_buttons.push print_name
  end
  
  def stat_printer( session, button )
    stat_name = "#{self.name}:#{button}:#{session.owner.login_name}"
    stat = Entities.Statics.get(stat_name)
    if stat.data_str == ""
      stat.data_str = get_server_printers.first
    end
    stat
  end
  
  def cmd_printer( session, button )
    cmd = nil
    pn = stat_printer( session, button ).data_str
    remote = session.web_req.peeraddr[3]
    dputs(3){"Found printer #{pn} with remote #{remote}"}
    if pn != "PDF"
      if get_server_printers.index( pn )
        cmd = "lp -o fitplot -d #{pn.sub(/^server /, '')}"
      elsif get_remote_printers( remote ).index( pn )
        cmd = "lp -o fitplot -h #{remote}:631 -d #{pn}"
      end
    end
    dputs(3){"Command will be #{cmd}"}
    cmd
  end

  def reply_print(session)
    ret = []
    @printer_buttons.each{|pb|
      p = stat_printer( session, pb )
      dputs(4){"#{pb}-#{p.inspect}"}
      value = "#{GetText._( pb.to_s )} #{p.data_str}"
      if session.web_req and ip = session.web_req.peeraddr[3]
        dputs(4){"#{session.web_req.inspect} - #{ip.inspect}"}
        # We're not looking for CUPS on the localhost, neither on Windows
        if ip =~ /(::1|localhost|127.0.0.1)/ or
            session.web_req.header["user_agent"] =~ /Windows/
          dputs(2){"Not looking for cups on #{ip} - #{session.web_req.header['user_agent']}"}
        else
          value = [ value ] + get_server_printers + get_remote_printers(ip)
        end
      end
      ret += reply( :update, pb => value )
    }
    dputs(4){"#{ret.inspect}"}
    ret
  end
  
  def rpc_print( session, name, data )
    dputs(4){"Printing button #{name} with #{data.inspect}"}
    if data and data['menu'] and data['menu'].length > 0
      stat_printer( session, name ).data_str = data['menu']
    end
    reply_print( session )
  end
end
