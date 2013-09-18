raskiidoc
=========

Rakefile to simplify generation of asciidoc documents.
Asciidoc generation can use complex arguments hard to remember, and could be document specific.

This rakefile (and parameters files) is an attempt to identify options to use during generation.

Clone Project with all submodules
---------------------------------
Raskiidoc allow you to use different asciidoc backends. To clone the project
with all submodules execute:

```bash
git clone --recursive https://github.com/llicour/raskiidoc.git
```

If you have already cloned the raskiidoc project, you can just clone all defined
submodules. To accomplish this, into raskiidoc project folder, execte:

```bash
git submodule init 
git submodule update
```

And all submodules will be downloaded.

Update submodules sources
-------------------------
If a submodules have changes, you can invoke a git pull to get anything
uptodate:

```bash
git submodule foreach git pull origin master
```

DeckJS Backend - Install Dependencies
-------------------------------------
If you want to use the deckJS backend, you need to install backend dependencies.
Are not included into the github project, because is a project mantained by
other developers.
To do this, enter into backend folder and execute a make command:

```bash
cd .rake/backends/asciidoc-deckjs/
make install-dep
```

You should see a little bit of output saying it is downloading deck.js project
files.


General configuration file
--------------------------
.rake/asciidoc.yaml

Document specific configuration file
------------------------------------
The name of the document must be the same, with a .yaml extension
<document>.yaml

Install slidy2 asciidoc configuration files (no backend installation required)
-----------------------------------------------------------------------------

```bash
sudo wget -O /etc/asciidoc/slidy2.conf https://asciidoc-slidy2-backend-plugin.googlecode.com/svn-history/r6/trunk/slidy2.conf
sudo wget -O /etc/asciidoc/stylesheets/slidy2.css https://asciidoc-slidy2-backend-plugin.googlecode.com/svn/trunk/stylesheets/slidy2.css
sudo wget -O /etc/asciidoc/stylesheets/slidy2_color_set_black.css https://asciidoc-slidy2-backend-plugin.googlecode.com/svn/trunk/stylesheets/slidy2_color_set_black.css
sudo wget -O /etc/asciidoc/stylesheets/slidy2_color_set_blue.css https://asciidoc-slidy2-backend-plugin.googlecode.com/svn/trunk/stylesheets/slidy2_color_set_blue.css
sudo wget -O /etc/asciidoc/stylesheets/slidy2_color_set_green.css https://asciidoc-slidy2-backend-plugin.googlecode.com/svn/trunk/stylesheets/slidy2_color_set_green.css
sudo wget -O /etc/asciidoc/stylesheets/slidy2_color_set_none.css https://asciidoc-slidy2-backend-plugin.googlecode.com/svn/trunk/stylesheets/slidy2_color_set_none.css
sudo wget -O /etc/asciidoc/stylesheets/slidy2_color_set_yellow.css https://asciidoc-slidy2-backend-plugin.googlecode.com/svn/trunk/stylesheets/slidy2_color_set_yellow.css
sudo wget -O /etc/asciidoc/javascripts/slidy2.js https://asciidoc-slidy2-backend-plugin.googlecode.com/svn/trunk/javascripts/slidy2.js
```

Install deckjs asciidoc backend
-----------------------------------------------------------------------------
```bash
wget -O deckjs.zip https://github.com/downloads/houqp/asciidoc-deckjs/deckjs-1.6.2.zip
asciidoc --backend install deckjs.zip
rm -f deckjs.zip
```

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

