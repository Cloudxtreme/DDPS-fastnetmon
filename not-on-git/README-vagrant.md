Building a custom FreeBSD boot ISO with Vagrant
===============================================
This repository builds a custom FreeBSD .iso unattended installer you can use
on any AMD64 platform. You can easily change the platform, and version of
FreeBSD, if you want. Just edit the Vagrantfile.

We use VirtualBox because it's free, but support for VMware and Parallels could
be added to the Vagrantfile.

We use an offical FreeBSD RELEASE box for Vagrant to bootstrap a FreeBSD
VirtualBox VM. 

We then fetch an offical FreeBSD-XX.X-RELEASE-amd64-disc1.iso to the VM, and
customize it using the installerconfig which is NFS mounted inside the VM. With
Vagrant provision we build a custom FreeBSD-XX.X-RELEASE-amd64-disc1-custom.iso
and place it in this folder. This custom.iso will install a FreeBSD AMD64
without any user intervention, exactly the same every time.

You need the following installed:

  * [VirtualBox](https://www.virtualbox.org)
  * [Vagrant](https://www.vagrantup.com)

When the above is installed clone this git repository to a local directory. It
should contain the files below, and probably a few more installconfig.?:

    $ tree
    ├── Vagrantfile
    ├── installerconfig
    ├── installerconfig.UFS
    └── installerconfig.ZFS

You just need the two textfiles Vagrantfile and installconfig to setup
everything!


### How to begin
All you need is VirtualBox and Vagrant installed, and the two textfiles
Vagrantfile and installconfig to setup everything.

From the directory containing the two textfiles, just run:

    $ vagrant up

This will take a while the first time you do it. It will fetch the FreeBSD
Vagrant box, and then provision it with specification in the file: Vagrantfile.
Which includes af FreeBSD RELEASE ISO. Change the Vagrantfile, if you want
another version.

It's around 1,5 GB in size, and will default be located in ~/.vagrant.d/boxes

If you see errors during the first run of 'vagrant up' ignore them, and just
wait. Vagrant will try to connect before it is ready. If you are curious you
can start Virtualbox, and see the console during the build process.

There will be a loong pause with the following on screen in red:

    default: /home/iso/FreeBSD-11.1-RELEASE-amd64-disc1.iso

It is the VM fetching the large FreeBSD RELEASE ISO. Just wait..

When it is finish it should produce a custom ISO file in the current directory

    FreeBSD-XX.X-RELEASE-amd64-disc1-custom.iso

You can now take this -custom.iso and boot it on hardware or in Virtualbox for
an unattended installation - or put it on you Zalman drive!

This -custom.iso is made with the ISO file from inside the VM and the
installconfig file in this directory. The installconfig is NFS mounted by the
VM and placed inside the offical FreeBSD ISO in /etc and a custom ISO is then
build using the VM. FreeBSD uses bsdinstall(8) and installconfig to
automatically install a new FreeBSD.

I have made two explames with UFS and ZFS. Just copy the one you want to
installconfig. 

    $ cp installerconfig.ZFS installerconfig

If you want your own, just make a installconfig.MY_OWN, and then copy it to
installconfig. Then provision it. You probably want one for each type of system.


### Provision an new custom ISO image
When you have made changes to the installconfig file just run:

    $ vagrant provision

And a new -custom.iso will be build. It will be alot faster the second time
around. Under 10 seconds.

You can make a Virtualbox VM and use the custom .iso to test the install. It
should install a complete FreeBSD without asking any questions and finish by
turning it off (so you can remove the ISO from the VM).

Login as 'root' no password.

We you are happy with the installconfig, remember to copy it to your own
installconfig.MY_OWN (or something clever)!


### When Vagrant is done provisioning the box you can SSH into it with
If you want to see something on the FreeBSD build machine, use:

    $ vagrant ssh


### When you are done, you can halt the VirtualBox image with
This will stop the VirtualBox VM from running.

    $ vagrant halt

To start it again run (alway from the directory of the Vagrantfile)

    $ vagrant up


### When you are completely done with the image, and want to remove everything
If you want to remove everything, even the FreeBSD Vagrant box, you first have
to find it. You can see all your Vagrant boxes with:

    $ vagrant box list

Remove the Vagrant box with:

    $ vagrant box remove freebsd/FreeBSD-XX.X-RELEASE

Remove the Virtualbox VM with:

    $ vagrant destroy

Remove the custom ISO with:

    $ rm -rf FreeBSD-XX.X-RELEASE-amd64-disc1-custom.iso

You can always build everything again from just the Vagrantfile and the
installconfig with:

    $ vagrant up
