raskiidoc
=========

Rakefile to simplify generation of asciidoc documents.
Asciidoc generation can use complex arguments hard to remember, and could be document specific.

This rakefile (and parameters files) is an attempt to identify options to use during generation.

General configuration file
--------------------------
.rake/asciidoc.yaml

Document specific configuration file
------------------------------------
The name of the document must be the same, with a .yaml extension
<document>.yaml


Usage
-----

cd sample

# generate all
rake

# force generate all (even if dates tell not to regenerate)
FORCE=1 rake

# generate one file
FILE=sample.asciidoc rake

# generate all pdf
rake pdf

# verbose generation
DEBUG=1 rake

# all together
FORCE=1 DEBUG=1 FILE=sample.asciidoc rake pdf

