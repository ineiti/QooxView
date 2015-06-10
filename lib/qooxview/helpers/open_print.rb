=begin
 Offers simple OpenOffice-find/replace stuff and printing 
=end

require 'rubygems'
require 'docsplit'
#require 'zip/zipfilesystem'; include Zip
require 'zip'

class OpenPrint
  attr_accessor :lp_cmd, :file

  def initialize(file, dir = nil)
    @file = file
    @dir = dir
    @base = File.basename file
    @lp_cmd = nil
    @counter = 0
  end

  def replace_accents(str)
    str = str.downcase.gsub(/ /, '_')
    accents = Hash[*%w( a àáâä e éèêë i ìíîï o òóôöœ u ùúûü c ç ss ß )]
    dputs(4) { "str was #{str}" }
    accents.each { |k, v|
      str.gsub!(/[#{v}]/, k)
    }
    str.gsub!(/[^a-z0-9_-]/, '_')
    dputs(4) { "str is #{str}" }
    str
  end

  def print_hash(fields, counter = nil, name = nil)
    print(fields.collect { |k, v| [/--#{k}--/, v] }, counter, name)
  end

  def get_content
    return unless File.exists? @file
    Zip::File.open(@file) { |z|
      z.read('content.xml').force_encoding(Encoding::UTF_8)
    }
  end

  def print_file(pdf_file)
    if @lp_cmd
      dputs(2) { "Printing with --#{@lp_cmd} #{pdf_file}--" }
      System.run_bool("#{@lp_cmd} #{pdf_file}")
      return true
    else
      # Download PDF
      return "#{pdf_file}"
    end
  end

  def self.replace(doc, fields)
    fields.each { |old, new|
      doc.gsub!(old, new.to_s)
      # For every -TAG- there can be a _TAG_ which is replaced with the
      # uppercase-version of 'new'
      old_up = old.inspect.sub(/^.-(.*)-.$/, '_\1_')
      doc.gsub!(old_up, new.to_s.upcase)
    }
    doc
  end

  def make_pdf(fields = [], counter = nil, name = nil)
    dputs(3) { "New print for -#{@file.inspect}-" }
    if name
      tmp_file = "/tmp/#{replace_accents(name)}.#{@base.sub(/.*\./, '')}"
    else
      counter ||= @counter
      tmp_file = "/tmp/#{counter}-#{@base}"
      @counter += 1
    end
    pdf_file = tmp_file.sub(/[^\.]*$/, 'pdf')
    dputs(3) { "Copying to -#{tmp_file.inspect}-" }

    FileUtils::cp(@file, tmp_file)
    Zip::File.open(tmp_file) { |z|
      doc = z.read('content.xml').force_encoding(Encoding::UTF_8)
      OpenPrint.replace(doc, fields)
      # Replace dates that need to be calculated with a '_'
      doc.gsub!(/(table:formula=[^<>]*date-value=").*?"/, '\1_\2"')
      z.get_output_stream('content.xml') { |f|
        f.write(doc)
      }
      z.commit
    }

    if ConfigBase.openprint_simul == %w(false)
      Docsplit.extract_pdf tmp_file, :output => '/tmp'
      #FileUtils::cp( tmp_file, pdf_file )
      dputs(5) { 'Finished docsplit' }
    else
      FileUtils::cp(tmp_file, pdf_file)
    end
    @dir and FileUtils::cp(pdf_file, @dir)
    pdf_file
  end

  def print(fields = [], counter = nil, name = nil)
    file = make_pdf(fields, counter, name)
    print_file(file)
  end

  def print_join(files, outfile = nil)
    outfile ||= files.first.sub(/.pdf$/, '-joined.pdf')
    OpenPrint.pdf_join(files, outfile)
    print_file(outfile)
  end

  # Input: 1..n files with 2 pages, front and back
  # Output: one 2x2-nup PDF front
  #         one 2x2-nup PDF back
  #         to be printed "long edge duplex"
  def self.pdf_nup_duplex(files, base = nil)
    Dir.mktmpdir { |dir|
      files.class == Array or files = [files]
      allpages = "#{dir}/allpages.pdf"
      cmd = "pdfjam --quiet --landscape --outfile #{allpages} " +
          files.join(" '1,2' ") + " '1,2,{},{}' "
      dputs(3) { "Running allpages-command #{cmd}" }
      %x[ #{cmd} ]

      pages_all = ((files.count + 1) & ~1).times
      documents = {:front => pages_all.collect { |i| (i ^ 1) * 2 + 1 }.join(','),
                   :back => pages_all.collect { |i| i * 2 + 2 }.join(',')}

      base ||= File.basename files.first, '.pdf'
      documents.collect { |suffix, pages|
        pages_file = "/tmp/#{base}-#{suffix}.pdf"
        cmd = 'pdfnup --quiet --landscape --nup 2x2 ' +
            "#{allpages} #{pages} --outfile #{pages_file}"

        dputs(3) { "Running pdfnup-command #{cmd}" }
        %x[ #{cmd} ]
        pages_file
      }
    }
  end

  # Input: 1..n files
  # Output: one PDF-file
  def self.pdf_join(files, outfile)
    files.class == Array or files = [files]
    System.run_bool "pdfjam --quiet --landscape --outfile #{outfile} #{files.join(' ')}"
  end
end

module PrintButton
  attr_reader :printer_buttons

  def call_lpstat(ip)
    if ConfigBase.use_printing.to_s == 'true'
      %x( which lpstat >/dev/null 2>&1 && lpstat -h #{ip}:631 -a 2>/dev/null |
          sed -e "s/ .*//" ).split
    else
      []
    end
  end

  def get_remote_printers(ip)
    if ip.match(ConfigBase.openprint_search)
      dputs(2) { "Getting printers for #{ip}" }
      call_lpstat(ip)
    else
      dputs(3) { "Not getting remote for #{ip}" }
      []
    end
  end

  def get_server_printers
    call_lpstat('localhost').collect { |p|
      "server #{p}"
    } + %w( PDF )
  end

  def show_print(*buttons)
    dputs(3) { "show_print with #{buttons.inspect}" }
    if not instance_variable_defined? :@printer_buttons
      @printer_buttons = []
    end
    print_name = nil
    buttons.to_a.each { |b|
      dputs(4) { "Doing #{b.inspect}" }
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

  def stat_printer(session, button)
    stat_name = "#{self.name}:#{button}:#{session.owner.login_name}"
    stat = Statics.get(stat_name)
    dputs(3) { "Getting printer #{stat_name} == #{stat.data_str}" }
    if stat.data_str == ''
      stat.data_str = get_server_printers.first
    end
    stat
  end

  def cmd_printer(session, button)
    cmd = nil
    pn = stat_printer(session, button).data_str
    remote = session.client_ip
    dputs(3) { "Found printer #{pn} with remote #{remote}" }
    if pn != 'PDF'
      if get_server_printers.index(pn)
        cmd = "lp -o media=a4 -o fitplot -d #{pn.sub(/^server /, '')}"
      elsif !(dp(session.web_req.header['user_agent']) =~ /Windows/) &&
          get_remote_printers(remote).index(pn)
        cmd = "lp -o media=a4 -o fitplot -h #{remote}:631 -d #{pn}"
      end
    end
    dputs(3) { "Command will be #{cmd}" }
    cmd
  end

  def send_printer(session, button, file)
    if cmd = cmd_printer(session, button)
      %x[ #{cmd} #{file} ]
      stat_printer(session, button).data_str
    else
      return nil
    end
  end

  def reply_print(session)
    #dputs_func
    ret = []
    @printer_buttons.each { |pb|
      p = stat_printer(session, pb)
      dputs(4) { "#{pb}-#{p.inspect}" }
      value = "#{GetText._(pb.to_s)} #{p.data_str}"
      if session.web_req && ip = session.client_ip
        # We're not looking for CUPS on the localhost, only on Macintosh and
        # non-android Linuxes
        ua = session.web_req.header['user-agent']
        ua &&= ua.first
        if ip =~ /(::1|localhost|127.0.0.1)/
          ddputs(3) { "Not looking for cups on #{ip} - #{session.web_req.header['user-agent']}" }
        elsif ua =~ /(Macintosh|Linux)/ && !(ua =~ /Android/)
          value = [value] + get_server_printers + get_remote_printers(ip)
        end
      end
      ret += reply(:update, pb => value)
    }
    dputs(4) { "#{ret.inspect}" }
    ret
  end

  def rpc_print(session, name, data)
    #dputs_func
    dputs(4) { "Printing button #{name} with #{data.inspect}" }
    if data and data['menu'] and data['menu'].length > 0
      stat_printer(session, name).data_str = data['menu']
    end
    reply_print(session)
  end

  def send_printer_reply(session, button, data, file)
    rpc_print(session, button, data) +
        reply(:window_show, :print_status) +
        reply(:update, :status =>
                         if printer = send_printer(session, button, file)
                           "Printed to #{printer}"
                         else
                           "<a href='#{file}' target='other'>#{file}</a>"
                         end)
  end

  def window_print_status
    gui_window :print_status do
      gui_vbox :nogroup do
        show_html :status
        show_button :close
      end
    end
  end
end
