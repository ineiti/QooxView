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