require 'rubygems'
require 'fileutils'
require 'yaml'
require 'pp'
require 'erb'

$DEBUG=1

$pdf_folder      = "pdf"  # Where you generate your pdf files
$html_folder     = "html" # Where you generate your html files

# sections possibles du fichier de configuration
$sections = [ "asciidoc::pdf::attributes", "asciidoc::pdf::options", "asciidoc::pdf::config",
              "asciidoc::html::attributes", "asciidoc::html::options", "asciidoc::html::config",
              "a2x::options",
              "dblatex::options", "dblatex::params", "dblatex::xsl",
              "html::copy_global_resources", "html::copy_resources",
]

# Sections dont parametres doivent etre uniques
$sections_uniq = [ "dblatex::params" ]

################################################################################
desc "help task"
################################################################################
task :help do
  puts "Usage : [FORCE] [DEBUG] [MODE] [FILE] rake"
  puts
  puts "  FORCE=1         : force regeneration"
  puts "  DEBUG=1         : verbose mode"
  puts "  DEBUG=2         : debug mode"
  puts "  MODE=pdf        : pdf only"
  puts "  MODE=html       : html only"
  puts "  FILE=<filename> : filename only"
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
    $force   = (ENV["FORCE"].nil?)?false:true
    $mode    = (ENV["MODE"].nil?)?"all":ENV["MODE"]
    $curdir  = ENV["PWD"]

    # Load config file
    begin
      $conf = YAML.load_file("#{$confdir}/asciidoc.yaml")
    rescue
      puts "Unable to locate #{$confdir}/asciidoc.yaml"
      $conf = {}
    end
    $sections.each {|o|
      $conf[o] = [] if $conf[o].nil?
    }

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
    end

    if $mode == "all" or $mode == "pdf"
      Rake::Task[:genpdf].invoke(Array.new(filelist))
    end
    if $mode == "all" or $mode == "html"
      Rake::Task[:genhtml].invoke(Array.new(filelist))
    end
end


################################################################################
# Read optional file parameters
################################################################################
def ReadConfig(filename)

    # Deep copy 
    conf = Marshal.load( Marshal.dump($conf) )

    extname = File.extname(filename)
    optfile = filename.gsub(extname, ".yaml")
    if File.exists?(optfile)
      begin
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
    end

    conf["filename"] = filename
    conf["dir"] = File.dirname(filename)
    return conf
end

################################################################################
# Get asciidoc options
################################################################################
def getOptionsAsciidoc(conf, type)

    # asciidoc options
    asciidocopts = ""
    conf["asciidoc::" + type.to_s + "::options"].each {|o|
      asciidocopts += "#{o} "
    } 
    conf["asciidoc::" + type.to_s + "::attributes"].each {|o|
      asciidocopts += "-a #{o} "
    } 
    conf["asciidoc::" + type.to_s + "::config"].each {|o|
      if o[0] !~ /^(\/|~)/
        o = "#{$confdir}/asciidoc/#{o}" if File.exists?("#{$confdir}/asciidoc/#{o}")
        o = "#{conf["dir"]}/#{o}"       if File.exists?("#{conf["dir"]}/#{o}")
      end

      if File.exists?(o)
        asciidocopts += "-f #{o} "
      else
        puts "Skip missing config file : #{o}"
      end
    }
    return asciidocopts
end

################################################################################
# Copy files (html resources images...)
################################################################################
def CopyResources(conf, type)

    return if conf[type].nil?

    # Copy resources
    conf[type].each {|r|
      next if ! File.exists?("#{$curdir}/#{r}")
      opts = ""
      opts += "-v " if $debug
      cmd = "rsync -a #{opts} #{$curdir}/#{r} #{$curdir}/#{$html_folder}/"
      puts "Executing : #{cmd}" if $verbose
      res = %x[#{cmd}]
      puts res if res != ""
    }

end


################################################################################
desc "Generate PDF files from .asciidoc or .txt files"
################################################################################
task :genpdf, [:filelist] do |t, args|
    args.with_defaults(:filelist => [])
    filelist = args[:filelist]

    # List of dependences 
    srcfiles = [ "-revhistory.xml", ".yaml" ]

    # Templatisation config a2x
    a2xconf = ERB.new File.new("#{$confdir}/a2x.conf.tpl").read
    File.open("#{$confdir}/a2x.conf", 'w') do |f|
      f.write a2xconf.result(binding)
    end

    until filelist.empty?
        Thread.new { 
            filename = filelist.pop
            next if filename.nil?

            puts "Processing #{filename}\n" if $verbose
            extname = File.extname(filename)
            dir = File.dirname(filename)
            file = File.basename(filename)
            outdir = "#{dir}/#{$pdf_folder}"
            FileUtils.mkpath outdir if ! File.directory?(outdir)
            outfile = "#{outdir}/" + file.gsub(extname, ".pdf")

            # need to regenerate pdf ?
            generate = false
            if File.exists?(outfile)
              generate = true if File.mtime(filename) > File.mtime(outfile)
              srcfiles.each {|s|
                f = filename.gsub(extname, s)
                generate = true if File.exists?(f) and File.mtime(f) > File.mtime(outfile)
              }
            else
              generate = true
            end
            
            # merge global/local yaml config 
            conf = ReadConfig(filename)

            if generate or $force
              opts = ""
              opts += "--conf-file #{$confdir}/a2x.conf " if File.exists?("#{$confdir}/a2x.conf")

              # asciidoc options
              asciidocopts = getOptionsAsciidoc(conf, :pdf)
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
                  o = "#{dir}/#{o}"      if File.exists?("#{dir}/#{o}")
                end

                if File.exists?(o)
                  dblatexopts += "-p #{o} "
                else
                  puts "Skip missing config file : #{o}"
                end
              }
              opts += "--dblatex-opts \"#{dblatexopts}\" " if dblatexopts != ""
              # where to find images...
              opts += "--dblatex-opts \"-I #{dir}\" "

              # a2x options
              conf["a2x::options"].each {|o|
                opts += "#{o} "
              }
              opts += "-v " if $debug

              # Generate docbook metadata file : *-docinfo.xml
              cmd = "python .rake/tools/asciidoc-tools/docinfo_generator.py #{filename}"
              puts "Executing : #{cmd}" if $verbose
              res = %x[#{cmd}]
              puts res if res != ""

              cmd = "a2x -D #{outdir} #{opts} #{filename}"
              puts "Generating #{outfile}\n"
              puts "Executing : #{cmd}" if $verbose
              res = %x[#{cmd}]
              puts res if res != ""
            end
        } unless Thread.list.length > 32
    end
    loop do
        if Thread.list.length < 2
            break
        end
        sleep 0.1
    end
end


################################################################################
desc "Generate HTML files from .asciidoc files"
################################################################################
task :genhtml, [:filelist, :theme, :backend] do |t, args|
    args.with_defaults(:filelist => [], :theme => "pryz", :backend => "lofic_backend")
    filelist = args[:filelist]

    # List of dependences 
    srcfiles = [ ".yaml" ]

    until filelist.empty?
        Thread.new { 
            filename=filelist.pop
            next if filename.nil?

            puts "Processing #{filename}\n" if $verbose
            extname = File.extname(filename)
            dir = File.dirname(filename)
            file = File.basename(filename)
            outdir = "#{dir}/#{$html_folder}"
            FileUtils.mkpath outdir if ! File.directory?(outdir)
            outfile = "#{outdir}/" + file.gsub(extname, ".html")

            # need to regenerate html ?
            generate = false
            if File.exists?(outfile)
              generate = true if File.mtime(filename) > File.mtime(outfile)
              srcfiles.each {|s|
                f = filename.gsub(extname, s)
                generate = true if File.exists?(f) and File.mtime(f) > File.mtime(outfile)
              }
            else
              generate = true
            end

            # merge global/local yaml config 
            conf = ReadConfig(filename)

            if generate or $force
              # Copy resources locales
              CopyResources(conf, "html::copy_resources")

              # asciidoc options
              asciidocopts = getOptionsAsciidoc(conf, :html)

              asciidocopts += "-v " if $debug

              cmd = "asciidoc -o #{outfile} #{asciidocopts} --backend=#{args.backend} --theme=#{args.theme} #{filename}"
              puts "Generating #{outfile}\n"
              puts "Executing : #{cmd}" if $verbose
              res = %x[#{cmd}]
              puts res if res != ""
              #`sed -i '/^Last updated/d' #{fileout}`
            end
        } unless Thread.list.length > 32
    end
    loop do
        if Thread.list.length < 2
            break
        end
        sleep 0.1
    end

    # Copy resources globales (only once per rake call)
    CopyResources($conf, "html::copy_global_resources")

end


