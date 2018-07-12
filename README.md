
# DDPS fastnetmon installation and configuration

The following describes the installation of the detection engine _fastnetmon_, _influxdb_
and the _notify script_ as well as OpenVPN etc. on FreeBSD 11.

All parameters lives in a database and is exported from there to the configuration files.
The only exception are the OpenVPN and SSH keys.

A set of scripts helps to facilitate this; some must be installed on DDPS while other
may live on your laptop during the creation of the boot image.

  - [Creating FreeBSD 11 bootstrap image](vagrant/README.md) with [Vagrant](https://www.vagrantup.com)
  - [Add net FastNetMon host, edit configuration](src2/README.md)
  - [General (not updated) documentation](docs/README-fnm.md)

## License

DDPS is copyright 2015-2017 DeiC, Denmark

Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
(the "License"); you may not use this software except in compliance with the
License.

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

At least the following other licences apply:

  - [pavel-odintsov/fastnetmon](https://github.com/pavel-odintsov/fastnetmon/blob/master/LICENSE) is licensed under the - GNU General Public License v2.0
  - [PostgreSQL](https://www.postgresql.org/about/licence/) - essential an BSD license
  - [perl](https://dev.perl.org/licenses/) which also covers the used perl modules. Each license
    be found on [http://search.cpan.org](http://search.cpan.org).
