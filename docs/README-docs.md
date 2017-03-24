
# Installation of DDPS fastnetmon

Documents here:

  - Installation of [10Gb drivers on the SuperMicro](10Gbs-debian-install-on-supermicro.md)
  - Installation of [fastnetmon and influxdb](influxdb-and-fastnetmon.md)
  - Installation of the [fastnetmon notification script](../src/README.md)

# Docs - where to put what

The project template_ may also be used as a boiler template for writing
documentation in [markdown](https://daringfireball.net/projects/markdown/), see
the [article](https://en.wikipedia.org/wiki/Markdow) on Wikipedia on syntax
etc.

The _docs_ directory has the following structure adopted from
[TextBundle](textbundle.org):

  - **assets/CSS**: CSS for generating html and pdf files
  - **assets/img**: Images for your files
  - **media-source**: Image source if the image is created in e.g an OS X application

Compilation from markdown to other formats may be achieved using ``make`` - provided
the correct compilers are installed.
 
