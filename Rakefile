require 'rubygems'
require 'fileutils'
require 'yaml'
require 'pp'
require 'erb'
require 'tmpdir'
require 'tempfile'

$DEBUG=1

$options = { "pdf"    => {:path => "pdf",    :ext => "pdf",  :prog => "a2x"},
             "html"   => {:path => "html",   :ext => "html", :prog => "asciidoc" },
             "slidy2" => {:path => "slides", :ext => "html", :prog => "asciidoc" },
             "slidy"  => {:path => "slides", :ext => "html", :prog => "asciidoc" },
             "deckjs"  => {:path => "slides", :ext => "html", :prog => "asciidoc" },
}


# sections possibles du fichier de configuration
$sections = [
              "a2x::options",
              "dblatex::options", "dblatex::params", "dblatex::xsl", "dblatex::sty",
              "html::copy_global_resources", "html::copy_resources",
              "file::options",
              "gpg::recipients", "gpg::encrypt",
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

$globalConfFile = "raskiidoc.yaml"
$globalConfDir = "raskiidoc.d"


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
  puts "  target          : pdf, html, slidy, slidy2, deckjs"
  puts
end

################################################################################
desc "Default task : build html and index"
################################################################################
task :default do
    $basedir = __FILE__.gsub("/Rakefile", "")
    $confdir = __FILE__.gsub("Rakefile", "") + ".rake"
    $confdir = nil if ! File.directory?($confdir)
    $verbose = (ENV["DEBUG"].nil?)?false:true
    $debug   = (ENV["DEBUG"].nil?)?false:(ENV["DEBUG"].to_i > 1)?true:false
    $debug2  = (ENV["DEBUG"].nil?)?false:(ENV["DEBUG"].to_i > 2)?true:false
    $debug3  = (ENV["DEBUG"].nil?)?false:(ENV["DEBUG"].to_i > 3)?true:false
    $force   = (ENV["FORCE"].nil?)?false:true
    $curdir  = ENV["PWD"]
    if $curdir =~ / /
      puts "Error : unable to process on directory with spaces : " + $curdir
      exit(1)
    end


    $conf = ReadGlobalConfig()

    $conf[:tmpDir] = Dir.mktmpdir

    # Templating files
    $conf[:tplOutDir] = "#{$conf[:tmpDir]}/templates"
    FileUtils.mkpath $conf[:tplOutDir] if ! File.directory?($conf[:tplOutDir])
    Dir.glob("#{$confdir}/**/*.tpl") {|tpl|
      tploutfile = "#{$conf[:tplOutDir]}/" + tpl.gsub("#{$confdir}/", "").gsub(/.tpl$/, "")
      FileUtils.mkpath File.dirname(tploutfile) if ! File.directory?(File.dirname(tploutfile))
      tplfile = ERB.new File.new(tpl).read
      File.open(tploutfile, 'w') do |f|
        f.write tplfile.result(binding)
      end
    }

    filelist = []
    if ENV["FILE"].nil?
      # Generate valid asciidoc file list
      txtfilelist = Dir.glob("#{$curdir}/*.txt") || []
      adocfilelist = Dir.glob("#{$curdir}/*.asciidoc") || []
      (txtfilelist + adocfilelist).each {|file|
        f = File.open(file, 'r', :encoding => "UTF-8")
        l1 = f.gets
        l2 = f.gets
        f.close
        filelist.push file if l1 =~ /^= / or l2 =~ /^(=|-)+$/
      }

      gpgtxtfilelist = Dir.glob("#{$curdir}/*.txt.gpg") || []
      gpgadocfilelist = Dir.glob("#{$curdir}/*.asciidoc.gpg") || []
      (gpgtxtfilelist + gpgadocfilelist).each {|file|
        filelist.push file
      }
    else
      if ENV["FILE"] =~ /^\// and File.exists?(ENV["FILE"])
        filelist.push = ENV["FILE"]
      elsif File.exists?($curdir + "/" + ENV["FILE"])
        filelist.push $curdir + "/" + ENV["FILE"]
      else
        puts "Error : unable to locate " + ENV["FILE"]
        exit 1
      end
      $force = true
    end
    filelist.each {|f|
      if f =~ / /
        puts "Error : unable to process filename with space : " + f
        exit(1)
      end
    }

    Rake::Task[:gen].invoke(Array.new(filelist))

    FileUtils.remove_entry $conf[:tmpDir]
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
task :deckjs do
    $filter = :deckjs
    Rake::Task[:default].execute()
end


################################################################################
# Doc Class
################################################################################
class Doc

  attr_reader :filename, :extname, :dir, :file, :filename_ori

  def initialize(filename)
    @filename = filename
    @extname = File.extname(@filename)
    @dir = File.dirname(@filename)
    @file = File.basename(@filename)
    @convert_attr = nil
    @filename_ori = nil

    if @extname == ".gpg"
      ext = File.extname(@filename.gsub(".gpg", ""))
      @ConfFile = @dir + "/" + @file.gsub(ext + ".gpg", "") + ".yaml"
    else
      @ConfFile = @dir + "/" + @file.gsub(@extname, "") + ".yaml"
    end
    @conf = self.ReadConfig()

    # Get convert instructions from config file
    if ! @conf["file::options"].grep(/^:noconvert:$/).empty?
      puts "Skip processing #{@filename} (noconvert tag)\n" if $verbose
      return
    end

    if self.mustBeEncrypted?
      if @extname == ".gpg"
        if File.exists?(@filename.gsub(/\.gpg$/, ""))
          puts "Error : both encrypted and unencrypted version of #{filename} detected"
          exit 1
        end
      else 
        if File.exists?(@filename + ".gpg")
          puts "Error : both encrypted and unencrypted version of #{filename} detected"
          exit 1
        end

        return if ! self.encrypt()
      end
    else
      if @extname == ".gpg"
        puts "Error : encrypted #{filename} detected. Please update 'gpg::encrypted' in #{@ConfFile}"
        exit 1
      else
        if File.exists?(@filename + ".gpg")
          puts "Error : both encrypted and unencrypted version of #{filename} detected (not flagged to be encrypted)"
          exit 1
        end
        
      end
    end

    if @extname == ".gpg"
      return if ! self.decrypt()
    end

    begin
      @content = IO.readlines(@filename, :encoding => "UTF-8")
    rescue => err
      puts "Exception: #{err}"
      return
    end

    # check asciidoc format
    if @content[0] !~ /^= / and @content[1] !~ /^(=|-)+$/
      puts "Skip processing #{@filename} (no asciidoc document)\n" if $verbose
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

  def decrypt
      # 1st, check all keys
      if @conf["gpg::recipients"].nil?
        puts "WARNING : gpg recipients can't be validated. Please configure 'gpg::recipients'"
      else
        cmd = "LANG= gpg --list-only -v #{@filename} 2>&1  | awk '/public key is/{print $5}' | xargs gpg --list-keys --with-colons | awk -F: '/^pub/{print substr($5,9),$10}'"
        puts "Executing : #{cmd}" if $verbose
        res = %x[#{cmd}]
        if $? != 0
          puts "Error : unable to check gpg file #{@filename}. Skip file"
          return false
        end

        keys = res.split("\n").map {|x| x[0..7]}
        diff1 = @conf["gpg::recipients"] - keys
        diff2 = keys - @conf["gpg::recipients"]
        if not diff1.empty? or not diff2.empty?
          puts "WARNING : invalid gpg recipients for #{@filename}"
          diff1.each {|k|
            puts "  - missing key #{k} (reencrypt with recipient)"
          }
          diff2.each {|k|
            puts "  - unknown key #{k} (not defined in configuration)"
          }
          puts " Current gpg recipients :"
          res.split("\n").each {|k|
            puts "  - key #{k[0..7]} : #{k[9..-1]}"
          }
        end
          
      end

      tempfile = Tempfile.new(@file.gsub(@extname, "")+".", @dir).path
      puts "Decrypting #{@filename} as " + File.basename(tempfile) + "..."
      cmd = "gpg --decrypt --quiet --use-agent --yes --output #{tempfile} #{@filename}"
      puts "Executing : #{cmd}" if $verbose
      res = %x[#{cmd}]
      puts res if res != ""
      if $? != 0
        puts "Error : unable to decrypt #{@filename}. Skip file"
        return false
      end

      @filename_ori = @filename
      @filename = tempfile
      @extname = File.extname(@filename_ori.gsub(".gpg", ""))
      @file = File.basename(@filename_ori.gsub(".gpg", ""))

      return true
  end

  # identify if document is flagged to be encrypted
  def mustBeEncrypted?
    return false if @conf["gpg::encrypt"].nil? or @conf["gpg::encrypt"] != TRUE
    return true
  end

  def encrypted?
      return false if self.filename_ori.nil?
      return true
  end

  def encrypt
      puts "Encrypting #{@filename} ..."

      gpgfilename = @filename + ".gpg"
      if @conf["gpg::recipients"].nil? or @conf["gpg::recipients"].length == 0
        puts "gpg error : unable to find recipient for document " + @filename
        return false
      end
      opts = ""
      @conf["gpg::recipients"].each {|r|
        opts += "-r #{r} "
      }
      cmd = "gpg --encrypt --output #{gpgfilename} #{opts} #{@filename}"
      puts "Executing : #{cmd}" if $verbose
      res = %x[#{cmd}]
      puts res if res != ""
      if $? != 0
        puts "gpg error : unable to encrypt #{@filename}"
        return false
      end

      tempfile = Tempfile.new(@file+".", @dir).path
      FileUtils.cp(@filename, tempfile)
      puts "Removing unencrypted document #{@filename}"
      File.unlink(@filename)

      @filename_ori = gpgfilename
      @filename = tempfile

      return true
  end
   
  def getConvertList
    return @convert_attr
  end

  ################################################################################
  # Read optional file parameters
  ################################################################################
  def ReadConfig()

    # Deep copy 
    puts "Reading global config file #{$conf[:globalConfFile]}" if $verbose
    conf = Marshal.load( Marshal.dump($conf) )

    optfile = @ConfFile
    conf["conffile"] = optfile
    conf["filename"] = @filename
    conf["dir"] = @dir

    if File.exists?(optfile)
      begin
        puts "Reading specific config file #{optfile}" if $verbose
        c = YAML.load_file(optfile)
        raise "Invalid yaml file" if not c

        # surcharge d'options
        $sections.each {|s|
          next if c[s].nil?
          if c[s].class == Array
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
          else
            conf[s] = c[s]
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
           conf[k][i].gsub!(/%B/, $basedir) if conf[k][i].class == String
           conf[k][i].gsub!(/%b/, $confdir) if conf[k][i].class == String
           conf[k][i].gsub!(/%D/, @dir) if conf[k][i].class == String
        }
      else
        conf[k].gsub!(/%B/, $basedir) if conf[k].class == String
        conf[k].gsub!(/%b/, $confdir) if conf[k].class == String
        conf[k].gsub!(/%D/, @dir) if conf[k].class == String
      end
    }

    return conf
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

    m = /^:convert: (?<type>pdf|html|slidy|slidy2|deckjs)(?<convopts>,.*)*$/.match(convert)
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
      @outfile = @outfile.gsub(/%B/, $basedir)
      @outfile = @outfile.gsub(/%b/, $confdir)
      @outdir = File.dirname(@outfile)
      FileUtils.mkpath @outdir if ! File.directory?(@outdir)
    end
     
    # merge global/local yaml config 
    @ConfFile = "%R.yaml" if @ConfFile.nil?
    @conf = self.ReadConfig()

    pp @conf if $debug3
  end

  ################################################################################
  # Need to regenerate output file ?
  ################################################################################
  def convertNeed?

    # List of dependences 
    srcfiles = [ "-revhistory.xml" ]

    return true if not File.exists?(@outfile)

    if @doc.encrypted?
      filename = @doc.filename_ori
    else
      filename = @doc.filename
    end
    return true if File.mtime(filename) > File.mtime(@outfile)
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
        t = t.gsub(/%B/, $basedir)
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

    a2xConf = ""
    a2xConf = "#{$conf[:tplOutDir]}/a2x.conf" if File.exists?("#{$conf[:tplOutDir]}/a2x.conf")
    a2xConf = "#{$confdir}/a2x.conf"          if File.exists?("#{$confdir}/a2x.conf")
    a2xConf = "#{@doc.dir}/a2x.conf"          if File.exists?("#{@doc.dir}/a2x.conf")
    opts += "--conf-file #{a2xConf} " if File.exists?(a2xConf)
  
    # asciidoc options
    asciidocopts = self.getOptionsAsciidoc()
    opts += "--asciidoc-opts \"#{asciidocopts}\" " if asciidocopts != ""
  
    # dblatex options
    dblatexopts = ""
    dblatexopts += "--output=#{@outfile} "
    conf["dblatex::options"].each {|o|
      dblatexopts += "#{o} "
    }
    conf["dblatex::params"].each {|o|
      o = o.gsub(/"/, "\\\"")
      dblatexopts += "-P #{o} "
    }
    conf["dblatex::xsl"].each {|o|
      if o[0] !~ /^(\/|~)/
        o = "#{$conf[:tplOutDir]}/dblatex/#{o}" if File.exists?("#{$conf[:tplOutDir]}/dblatex/#{o}")
        o = "#{$confdir}/dblatex/#{o}"          if File.exists?("#{$confdir}/dblatex/#{o}")
        o = "#{@doc.dir}/#{o}"                  if File.exists?("#{@doc.dir}/#{o}")
      end
  
      if File.exists?(o)
        dblatexopts += "-p #{o} "
      else
        puts "Skip missing config file : #{o}"
      end
    }
    conf["dblatex::sty"].each {|o|
      if o[0] !~ /^(\/|~)/
        o = "#{$conf[:tplOutDir]}/dblatex/#{o}" if File.exists?("#{$conf[:tplOutDir]}/dblatex/#{o}")
        o = "#{$confdir}/dblatex/#{o}"          if File.exists?("#{$confdir}/dblatex/#{o}")
        o = "#{@doc.dir}/#{o}"                  if File.exists?("#{@doc.dir}/#{o}")
      end
  
      if File.exists?(o)
        dblatexopts += "-s #{o} "
      else
        puts "Skip missing config file : #{o}"
      end
    }
    opts += "--dblatex-opts \"#{dblatexopts}\" " if dblatexopts != ""
  
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
          o = "#{$conf[:tplOutDir]}/asciidoc/#{o}" if File.exists?("#{$conf[:tplOutDir]}/asciidoc/#{o}")
          o = "#{$confdir}/asciidoc/#{o}"          if File.exists?("#{$confdir}/asciidoc/#{o}")
          o = "#{@conf["dir"]}/#{o}"               if File.exists?("#{@conf["dir"]}/#{o}")
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
    optfile = optfile.gsub(/%B/, $basedir)
    optfile = optfile.gsub(/%b/, $confdir)

    conf["conffile"] = optfile
    conf["filename"] = @doc.filename
    conf["dir"] = @doc.dir

    if File.exists?(optfile)
      begin
        puts "Reading specific config file #{optfile}" if $verbose
        c = YAML.load_file(optfile)
        raise "Invalid yaml file" if not c

        # surcharge d'options
        $sections.each {|s|
          next if c[s].nil?
          if c[s].class == Array
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
          else
            conf[s] = c[s]
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
           conf[k][i].gsub!(/%B/, $basedir) if conf[k][i].class == String
           conf[k][i].gsub!(/%b/, $confdir) if conf[k][i].class == String
           conf[k][i].gsub!(/%D/, @doc.dir) if conf[k][i].class == String
        }
      else
        conf[k].gsub!(/%B/, $basedir) if conf[k].class == String
        conf[k].gsub!(/%b/, $confdir) if conf[k].class == String
        conf[k].gsub!(/%D/, @doc.dir) if conf[k].class == String
      end
    }

    return conf
  end

end


################################################################################
# Read optional file parameters
################################################################################
def ReadGlobalConfig()

  # Load config file
  begin
    conf = YAML.load_file("#{$confdir}/#{$globalConfFile}")
  rescue
    puts "Unable to locate #{$confdir}/#{$globalConfFile}"
    conf = {}
  end

  Dir.glob("#{$confdir}/#{$globalConfDir}/*.yaml") {|f|
    begin
      conf.merge!(YAML.load_file(f))
    rescue
      puts "Unable to locate #{f}"
      conf = {}
    end
  }

  $sections.each {|o|
    conf[o] = [] if conf[o].nil?
  }
  conf[:globalConfFile] = "#{$confdir}/#{$globalConfFile}"
  conf[:globalConfDir] = "#{$confdir}/#{$globalConfDir}"

  altConfFile = "#{$curdir}/.rake/#{$globalConfFile}"
  if File.exists?(altConfFile)
    begin
      puts "Reading local config file #{altConfFile}" if $verbose
      c = YAML.load_file(altConfFile)
      raise "Invalid yaml file" if not c

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
      puts "Error loading #{altConfFile}"
    end
  end
  
  conf.each {|k,v|
    if v.class == Array
      conf[k].each_index {|i|
         conf[k][i].gsub!(/%B/, $basedir) if conf[k][i].class == String
         conf[k][i].gsub!(/%b/, $confdir) if conf[k][i].class == String
      }
    else
      conf[k].gsub!(/%B/, $basedir) if conf[k].class == String
      conf[k].gsub!(/%b/, $confdir) if conf[k].class == String
    end
  }

  return conf
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


