#
# Makefile for (multi)-markdown to html and pdf projects
#
# Notice:
#
#     pdf requires wkhtmltopdf, while html  requires  multimarkdown. Both  appli-
#     cations are installed on the hosts office and buh and  available in  source
#     format.
#  
# Generic tasks:
#
#	- If you have only one markdown file you are more or less done. Edit / create
#	  your file and use the extension md.  Media files readable in html goes into
#	  e.g.  assets/img,  source  for images (e.g. created in an OS X application)
#	  shuld stay in media-source.
#	- Change author to your name and do ``make document.html and document.pdf``.
#
#	- If you have more than one document then go ``make document.mmd`` first  and
#	  edit to your heart desire (add files to the file: part). Then run  make for
#	  the html and pdf versions.
#
#	  If the arguments to wkhtmltopdf doesn't fit, then feel free to add your own
#	  specific target to the Makefile. The same goes for your choice of css.  The
#	  assets/CSS contains a number of excellent stating points.
#

date	= `date`
version	= `git describe --long --dirty --tags --always`
author	= Niels Thomas Haugård

# Default css: black text, blue headers, automatic numbering
css		= assets/CSS/nth2-number.css

# Syntax highlighting - see https://highlightjs.org
html_header = <link rel=\"stylesheet\" href=\"assets/CSS/_TYPE_.css\"> <script src=\"assets/CSS/highlight.min.js\"></script> <script>hljs.initHighlightingOnLoad();</script>

# Pick the one you like -- I prefer googlecode
highlight = default
highlight = grayscale
highlight = googlecode

# If you have a specific target add it here, e.g.:
# 
# mdfiles = file.md file1.md file2.md file3.md
#
# test.mmd:
# 	# heredoc doesn't work in Makefile
# 	echo "Title:  Status"		>	$@
# 	echo "Subtitle:Status"		>>	$@
# 	echo "Author:  $(author)"	>>	$@
# 	echo "Date:   $(date)"		>>	$@
# 	echo "Version: $(version)"	>>	$@
# 	echo "ShortTitle: D"		>>	$@
# 	echo "Series:  SSI"			>>	$@
# 	echo "SeriesIndex:"			>>	$@
# 	echo "Tags: SSI"			>>	$@
# 	echo "Cover: coverpage.pdf"	>>	$@
# 	echo "CSS:  $(css)"			>>	$@
# 	echo "html header: $(html_header)" | sed "s/_TYPE_/$(highlight)/g" >> $@
# 	echo "Files: $(mdfiles)"			>>	$@
# 
# html file from markdown
#%.html: %.md %.mmd
#	cat $(addsuffix .mmd, $(basename $<)) $< | multimarkdown --output=$(addsuffix .html, $(basename $<)) 	\
#
# 
# test.pdf: $(mdfiles) test.mmd
# 	wkhtmltopdf	--margin-top 15										\
# 				--margin-left 15									\
# 				--margin-right 15									\
# 				--margin-bottom 20									\
#				--print-media-type									\
# 				toc --toc-header-text Indholdsfortegnelse			\
# 				--enable-internal-links DPS.html					\
# 				--footer-font-name Ariel							\
# 				--footer-font-size 7 --footer-spacing 5				\
# 				--footer-left '[title], [isodate] [time]'			\
# 				--footer-right 'Side [page] af [topage]' DPS-body.pdf
# 				pdfunite coverpage.pdf test-body.pdf test.pdf
# 				/bin/rm -f DPS-body.pdf
# 
# Generic tasks below

# Metafile used by multimarkdown
%.mmd:
	# heredoc doesn't work in Makefile
	echo "Title:  Status"		>	$@
	echo "Subtitle:Status"		>>	$@
	echo "Author:  $(author)"	>>	$@
	echo "Date:   $(date)"		>>	$@
	echo "Version: $(version)"	>>	$@
	echo "ShortTitle: D"		>>	$@
	echo "Series:  SSI"			>>	$@
	echo "SeriesIndex:"			>>	$@
	echo "Tags: SSI"			>>	$@
	echo "Cover: coverpage.pdf"	>>	$@
	echo "CSS:  $(css)"			>>	$@
	echo "html header: $(html_header)" | sed "s/_TYPE_/$(highlight)/g" >> $@
	echo "Files: $<"			>>	$@

# html file from markdown
%.html: %.md %.mmd
	cat $(addsuffix .mmd, $(basename $<)) $< | multimarkdown --output=$(addsuffix .html, $(basename $<)) 	\

# create pdf from html, see manpage for wkhtmltopdf
%.pdf: %.html %.md %.mmd
	wkhtmltopdf	--margin-top 15 --margin-left 15 --margin-right 15								\
				--margin-bottom 20 																\
				--print-media-type																\
				$< --enable-internal-links --footer-font-name Ariel								\
				--footer-font-size 7 --footer-spacing 2											\
				--footer-line																	\
				--footer-left "[isodate] [time] $(version)" 									\
				--footer-right 'Page [page] of [topage]' $(addsuffix .pdf, $(basename $<))

# add toc by adding the line below before the --footer-font ... line above:
#  toc --toc-header-text "Indholdsfortegnelse"
# Add a first page (made separatly) by adding the line below after the last argument to wkhtmltopdf
# pdfunite coverpage.pdf $(addsuffix .pdf, $(basename $<)) $(addsuffix .pdf, $(basename $<))-with-coverpage.pdf


.SILENT:

.IGNORE:

