require 'rubygems'
require 'fileutils'
require 'yaml'
require 'pp'
require 'erb'

$DEBUG=1

$options = { "pdf"    => {:path => "pdf",    :ext => "pdf",  :prog => "a2x"},
             "html"   => {:path => "html",   :ext => "html", :prog => "asciidoc" },
             "slidy2" => {:path => "slides", :ext => "html", :prog => "asciidoc" },
             "slidy"  => {:path => "slides", :ext => "html", :prog => "asciidoc" },
}


# sections possibles du fichier de configuration
$sections = [
              "a2x::options",
              "dblatex::options", "dblatex::params", "dblatex::xsl", "dblatex::sty",
              "html::copy_global_resources", "html::copy_resources",
]
$options.keys.each {|t|
  $sections << "asciidoc::#{t}::attributes"
  $sections << "asciidoc::#{t}::options"
  $sections << "asciidoc::#{t}::config"
  $sections << "tools::#{t}::pre"
  $sections << "tools::#{t}::post"
}

# Sections dont parametres doivent etre uniques
$sections_uniq = [ "dblatex::params" ]

$globalConfFile = "asciidoc.yaml"


################################################################################
desc "help task"
################################################################################
task :help do
  puts "Usage : [FORCE] [DEBUG] [FILE] rake [target]"
  puts
  puts "  FORCE=1         : force regeneration"
  puts "  DEBUG=1         : verbose mode"
  puts "  DEBUG=2         : debug mode"
  puts "  DEBUG=3         : debug+ mode"
  puts "  DEBUG=4         : debug++ mode"
  puts "  FILE=<filename> : filename only"
  puts "  target          : pdf, html, slidy, slidy2"
  puts
end

################################################################################
desc "Default task : build html and index"
################################################################################
task :default do
    $confdir = __FILE__.gsub("Rakefile", "") + ".rake"
    $confdir = nil if ! File.directory?($confdir)
    $verbose = (ENV["DEBUG"].nil?)?false:true
    $debug   = (ENV["DEBUG"].nil?)?false:(ENV["DEBUG"].to_i > 1)?true:false
    $debug2  = (ENV["DEBUG"].nil?)?false:(ENV["DEBUG"].to_i > 2)?true:false
    $debug3  = (ENV["DEBUG"].nil?)?false:(ENV["DEBUG"].to_i > 3)?true:false
    $force   = (ENV["FORCE"].nil?)?false:true
    $curdir  = ENV["PWD"]

    # Load config file
    begin
      $conf = YAML.load_file("#{$confdir}/#{$globalConfFile}")
    rescue
      puts "Unable to locate #{$confdir}/#{$globalConfFile}"
      $conf = {}
    end
    $sections.each {|o|
      $conf[o] = [] if $conf[o].nil?
    }
    $conf[:globalConfFile] = "#{$confdir}/#{$globalConfFile}"

    filelist = []
    if ENV["FILE"].nil?
      # Generate valid asciidoc file list
      txtfilelist = Dir.glob("#{$curdir}/*.txt") || []
      adocfilelist = Dir.glob("#{$curdir}/*.asciidoc") || []
      (txtfilelist + adocfilelist).each {|file|
        f = File.open(file, 'r')
        l1 = f.gets
        l2 = f.gets
        f.close
        filelist.push file if l1 =~ /^= / or l2 =~ /^(=|-)+$/
      }
    else
      filelist.push $curdir + "/" + ENV["FILE"]
      $force = true
    end

    Rake::Task[:gen].invoke(Array.new(filelist))
end

task :pdf do
    $filter = :pdf
    Rake::Task[:default].execute()
end
task :html do
    $filter = :html
    Rake::Task[:default].execute()
end
task :slidy do
    $filter = :slidy
    Rake::Task[:default].execute()
end
task :slidy2 do
    $filter = :slidy2
    Rake::Task[:default].execute()
end

################################################################################
# Doc Class
################################################################################
class Doc

  attr_reader :filename, :extname, :dir, :file

  def initialize(filename)
    @filename = filename
    @extname = File.extname(@filename)
    @dir = File.dirname(@filename)
    @file = File.basename(@filename)
    @convert_attr = nil

    begin
      @content = IO.readlines(@filename)
    rescue => err
      puts "Exception: #{err}"
      return
    end

    if @content.grep(/^:noconvert:/).count != 0
      puts "Skip processing #{@filename} (noconvert tag)\n" if $verbose
      return
    end

    @convert_attr = @content.grep(/^:convert: /)
    if @convert_attr.count == 0
      puts "Skip processing #{@filename} (no convert tag)\n" if $verbose
    end
  end

  def getConvertList
    return @convert_attr
  end

end

################################################################################
# ConvertDoc Class
################################################################################
class ConvertDoc

  attr_reader :outdir, :outfile
  attr_reader :Type, :ConfFile, :Opts, :FullOpts
  attr_accessor :conf

  def initialize(doc, convert)
    @doc = doc

    m = /^:convert: (?<type>pdf|html|slidy|slidy2)(?<convopts>,.*)*$/.match(convert)
    if not m.nil?
      @Type = m[:type]
      convopts = m[:convopts]
    else
      puts "Skip converting #{@doc.file} (invalid convert attribute : #{convert})"
      return
    end
    return if not $filter.nil? and @Type != $filter.to_s

    if not m[:convopts].nil?
      m[:convopts].split(/,/).each do |o|
        /^outfile=([\w\-\%\.\/]+)$/.match(o) {|a|
          @outfile = a[1]
        }
        /^conffile=([\w\-\%\.\/]+)$/.match(o) {|a|
          @ConfFile = a[1]
        }
        /^opts=([\w\-\%\."' =]+)$/.match(o) {|a|
          @Opts = a[1]
        }
        /^fullopts=([\w\-\%\."' =]+)$/.match(o) {|a|
          @FullOpts = a[1]
        }
      end
    end
    
    if @outfile.nil?
      @outdir = @doc.dir + "/" + $options[@Type][:path]
      FileUtils.mkpath @outdir if ! File.directory?(@outdir)
      @outfile = "#{@outdir}/" + @doc.file.gsub(@doc.extname, ".#{$options[@Type][:ext]}")
    else
      if @outfile[0] !~ /^(\/|~)/
        @outfile = @doc.dir + "/" + $options[@Type][:path] + "/" + @outfile
      end

      @outfile = @outfile.gsub(/%f/, @doc.filename)
      @outfile = @outfile.gsub(/%F/, @doc.file)
      @outfile = @outfile.gsub(/%D/, @doc.dir)
      @outfile = @outfile.gsub(/%E/, @doc.extname)
      @outfile = @outfile.gsub(/%r/, @doc.file.gsub(@doc.extname, ""))
      @outfile = @outfile.gsub(/%t/, @Type)
      @outfile = @outfile.gsub(/%p/, $options[@Type][:path])
      @outfile = @outfile.gsub(/%b/, $confdir)
      @outdir = File.dirname(@outfile)
      FileUtils.mkpath @outdir if ! File.directory?(@outdir)
    end
     
    # merge global/local yaml config 
    @ConfFile = "%R.yaml" if @ConfFile.nil?
    @conf = self.ReadConfig()

    pp @conf if $debug
  end

  ################################################################################
  # Need to regenerate output file ?
  ################################################################################
  def convertNeed?

    # List of dependences 
    srcfiles = [ "-revhistory.xml" ]

    return true if not File.exists?(@outfile)

    return true if File.mtime(@doc.filename) > File.mtime(@outfile)
    return true if File.exists?($conf[:globalConfFile]) and File.mtime($conf[:globalConfFile]) > File.mtime(@outfile)
    return true if File.exists?(@ConfFile)              and File.mtime(@ConfFile)              > File.mtime(@outfile)
    srcfiles.each {|s|
      f = @doc.filename.gsub(@doc.extname, s)
      return true if File.exists?(f) and File.mtime(f) > File.mtime(@outfile)
    }

    return false
  end

  ################################################################################
  # Convert
  ################################################################################
  def convert
    case $options[@Type][:prog]
    when "a2x"
      self.ConvertA2X()
    when "asciidoc"
      self.ConvertASCIIDOC()
    else
      puts "Error prog : unsupported type : #{@Type}"
      exit 
    end
  end

  ################################################################################
  # Convert using a2x tool
  ################################################################################
  def ConvertA2X
    # a2x options
    if not @FullOpts.nil?
      opts = @FullOpts + " "
    else
      opts = self.getOptionsA2X()
    end

    opts += @Opts + " " if not @Opts.nil?

    opts += "-v " if $debug2
  
    # Execute pre actions
    self.ExecuteAction(:pre)
  
    cmd = "a2x -D #{@outdir} #{opts} #{@doc.filename}"
    puts "Generating (#{@Type}) #{@outfile}\n"
    puts "Executing : #{cmd}" if $verbose
    res = %x[#{cmd}]
    puts res if res != ""
  
    if $? == 0
      # Execute post actions
      self.ExecuteAction(:post)
    end

  end

  ################################################################################
  # Convert using asciidoc tool
  ################################################################################
  def ConvertASCIIDOC

    # asciidoc options
    if not @FullOpts.nil?
      opts = @FullOpts + " "
    else
      opts = self.getOptionsAsciidoc()
    end

    opts += @Opts + " " if not @Opts.nil?

    opts += "-v " if $debug2

    # Execute pre actions
    self.ExecuteAction(:pre)

    cmd = "asciidoc -o #{@outfile} #{opts} #{@doc.filename}"
    puts "Generating (#{@Type}) #{@outfile}\n"
    puts "Executing : #{cmd}" if $verbose
    res = %x[#{cmd}]
    puts res if res != ""

    if $? == 0
      # Execute post actions
      self.ExecuteAction(:post)
    end

  end

  ################################################################################
  # Execute action
  ################################################################################
  def ExecuteAction(typeAction)
    if not @conf["tools::" + @Type + "::" + typeAction.to_s].nil?
      @conf["tools::" + @Type + "::" + typeAction.to_s].each {|t|
        t = t.gsub(/%f/, @doc.filename)
        t = t.gsub(/%F/, @doc.file)
        t = t.gsub(/%D/, @doc.dir)
        t = t.gsub(/%E/, @doc.extname)
        t = t.gsub(/%r/, @doc.file.gsub(@doc.extname, ""))
        t = t.gsub(/%t/, @Type)
        t = t.gsub(/%o/, @outfile)
        t = t.gsub(/%O/, @outdir)
        t = t.gsub(/%b/, $confdir)
  
        cmd = "#{t}"
        puts "Executing (" + typeAction.to_s + ") : #{cmd}" if $verbose
        res = %x[#{cmd}]
        puts res if res != ""
      }
    end
  end

  ################################################################################
  # Get a2x options
  ################################################################################
  def getOptionsA2X()
    opts = ""

    # Templatisation config a2x
    a2xconf = ERB.new File.new("#{$confdir}/a2x.conf.tpl").read
    File.open("#{$confdir}/a2x.conf", 'w') do |f|
      f.write a2xconf.result(binding)
    end
    opts += "--conf-file #{$confdir}/a2x.conf " if File.exists?("#{$confdir}/a2x.conf")
  
    # asciidoc options
    asciidocopts = self.getOptionsAsciidoc()
    opts += "--asciidoc-opts \"#{asciidocopts}\" " if asciidocopts != ""
  
    # dblatex options
    dblatexopts = ""
    conf["dblatex::options"].each {|o|
      dblatexopts += "#{o} "
    }
    conf["dblatex::params"].each {|o|
      o = o.gsub(/"/, "\\\"")
      dblatexopts += "-P #{o} "
    }
    conf["dblatex::xsl"].each {|o|
      if o[0] !~ /^(\/|~)/
        o = "#{$confdir}/dblatex/#{o}" if File.exists?("#{$confdir}/dblatex/#{o}")
        o = "#{@doc.dir}/#{o}"         if File.exists?("#{@doc.dir}/#{o}")
      end
  
      if File.exists?(o)
        dblatexopts += "-p #{o} "
      else
        puts "Skip missing config file : #{o}"
      end
    }
    conf["dblatex::sty"].each {|o|
      if o[0] !~ /^(\/|~)/
        o = "#{$confdir}/dblatex/#{o}" if File.exists?("#{$confdir}/dblatex/#{o}")
        o = "#{@doc.dir}/#{o}"         if File.exists?("#{@doc.dir}/#{o}")
      end
  
      if File.exists?(o)
        dblatexopts += "-s #{o} "
      else
        puts "Skip missing config file : #{o}"
      end
    }
    opts += "--dblatex-opts \"#{dblatexopts}\" " if dblatexopts != ""
    # where to find images...
    opts += "--dblatex-opts \"-I #{@doc.dir}\" "
  
    opts += "--dblatex-opts \"-d\" " if $debug2
  
    # a2x options
    conf["a2x::options"].each {|o|
      opts += "#{o} "
    }

    return opts
  end

  ################################################################################
  # Get asciidoc options
  ################################################################################
  def getOptionsAsciidoc()

    # asciidoc options
    asciidocopts = ""
    if not @conf["asciidoc::" + @Type + "::options"].nil?
      @conf["asciidoc::" + @Type + "::options"].each {|o|
        asciidocopts += "#{o} "
      } 
    end

    if not @conf["asciidoc::" + @Type + "::attributes"].nil?
      @conf["asciidoc::" + @Type + "::attributes"].each {|o|
        asciidocopts += "-a #{o} "
      } 
    end

    if not @conf["asciidoc::" + @Type + "::config"].nil?
      @conf["asciidoc::" + @Type + "::config"].each {|o|
        if o[0] !~ /^(\/|~)/
          o = "#{$confdir}/asciidoc/#{o}" if File.exists?("#{$confdir}/asciidoc/#{o}")
          o = "#{@conf["dir"]}/#{o}"      if File.exists?("#{@conf["dir"]}/#{o}")
        end
  
        if File.exists?(o)
          asciidocopts += "-f #{o} "
        else
          puts "Skip missing config file : #{o}"
        end
      }
    end

    return asciidocopts
  end

  ################################################################################
  # Read optional file parameters
  ################################################################################
  def ReadConfig()

    # Deep copy 
    puts "Reading global config file #{$conf[:globalConfFile]}" if $verbose
    conf = Marshal.load( Marshal.dump($conf) )

    if @ConfFile.nil?
      return conf
    end

    optfile = @ConfFile
    optfile = optfile.gsub(/%f/, @doc.filename)
    optfile = optfile.gsub(/%F/, @doc.file)
    optfile = optfile.gsub(/%D/, @doc.dir)
    optfile = optfile.gsub(/%E/, @doc.extname)
    optfile = optfile.gsub(/%R/, @doc.dir + "/" + @doc.file.gsub(@doc.extname, ""))
    optfile = optfile.gsub(/%r/, @doc.file.gsub(@doc.extname, ""))
    optfile = optfile.gsub(/%t/, @Type)
    optfile = optfile.gsub(/%b/, $confdir)

    conf["conffile"] = optfile
    conf["filename"] = @doc.filename
    conf["dir"] = @doc.dir

    if File.exists?(optfile)
      begin
        puts "Reading specific config file #{optfile}" if $verbose
        c = YAML.load_file(optfile)

        # surcharge d'options
        $sections.each {|s|
          next if c[s].nil?
          if $sections_uniq.include?(s)
            # remove then add option
            c[s].each {|o|
              o2 = o.gsub(/=.*/, "=")
              conf[s].delete_if {|o3| o3.start_with?(o2)}
              conf[s].push o
            }
          else
            c[s].each {|o|
              if o[0] == "!"
                # delete option
                conf[s].delete o[1..-1]
              else
                # just add option
                conf[s].push o
              end
            }
          end
        }
      rescue
        puts "Error loading #{optfile}"
      end
    else
      puts "Skip loading unknown specific config file #{optfile}" if $verbose
    end

    conf.each {|k,v|
      if v.class == Array
        conf[k].each_index {|i|
           conf[k][i].gsub!(/%b/, $confdir)
        }
      else
        conf[k].gsub!(/%b/, $confdir)
      end
    }

    return conf
  end

end



################################################################################
desc "Generate xxx files from .asciidoc or .txt files"
################################################################################
task :gen, [:filelist] do |t, args|
    args.with_defaults(:filelist => [])
    filelist = args[:filelist]

    until filelist.empty?
#        Thread.new { 
            filename = filelist.pop
            next if filename.nil?
            doc = Doc.new(filename)
            next if doc.getConvertList.nil?

            (doc.getConvertList).each {|convert|
              convertDoc = ConvertDoc.new(doc, convert)
              next if convertDoc.Type.nil?
              next if not $filter.nil? and convertDoc.Type != $filter.to_s
              next if not convertDoc.convertNeed? and not $force

              convertDoc.convert
            }

#        } unless Thread.list.length >= 2
    end
    loop do
        if Thread.list.length < 2
            break
        end
        sleep 0.1
    end
end



