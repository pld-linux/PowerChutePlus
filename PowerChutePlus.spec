Summary:	UPS management software for APC UPS models
Name:		PowerChutePlus
Version:	4.5.2.1
Release:	2
Copyright:	(c) 1999 APC, inc.
Group:		Utilities/System
Source0:	ftp://ftp.apcc.com/apc/public/software/unix/linux/pcplus/4521/pc4521_glibc.tar
Source1:	ftp://ftp.apcc.com/apc/public/software/unix/linux/pcplus/4521/pclinxug.pdf
Source2:	upsd.init
Source3:	PowerChutePlus-xpowerchute.sh
Source4:	PowerChutePlus-Config.sh
Source5:	PowerChutePlus-powerchute.ini
Source6:	PowerChutePlus-powerchute.ini_templ
Patch:		PowerChutePlus-fix-sh.patch
ExclusiveOS:	linux
ExclusiveArch:	%{ix86}
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
This program allows users to safely shut down their system in response
to power failures and other power events. It also allows users to
configure and manage UPS models.

Please note that /usr/lib/powerchute/Config.sh should be run in order
to configure PowerChute plus.

%prep
%setup -q -c
for i in BI_LINUX CI_LINUX COMMON FI_LINUX HELP ; do
	tar xf $i
done
%patch0 -p1

%build
# No build, binaty package

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT{%{_sbindir},%{_libdir}/powerchute} \
	$RPM_BUILD_ROOT/etc/rc.d/init.d \
	$RPM_BUILD_ROOT/usr/X11R6/{bin,lib/X11/{app-defaults,uid}}

install %{SOURCE1} .
install %{SOURCE2} $RPM_BUILD_ROOT/etc/rc.d/init.d/upsd
install %{SOURCE3} $RPM_BUILD_ROOT/usr/X11R6/bin/xpowerchute
install %{SOURCE4} $RPM_BUILD_ROOT%{_libdir}/powerchute/Config.sh
install %{SOURCE6} $RPM_BUILD_ROOT%{_libdir}/powerchute/powerchute.ini_templ
install %{SOURCE5} $RPM_BUILD_ROOT/etc/powerchute.ini

ln -s /etc/powerchute.ini $RPM_BUILD_ROOT%{_libdir}/powerchute/

install _upsd $RPM_BUILD_ROOT%{_sbindir}/upsd

install _xpwrchute $RPM_BUILD_ROOT%{_libdir}/powerchute
install addpage.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install apacheshut $RPM_BUILD_ROOT%{_libdir}/powerchute
install bkupsd $RPM_BUILD_ROOT%{_libdir}/powerchute
install dialpager.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install killbk.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install killpc.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install machine_id $RPM_BUILD_ROOT%{_libdir}/powerchute
install mailer.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install notifier.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install pcshut.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install portcheck $RPM_BUILD_ROOT%{_libdir}/powerchute
install ttycheck $RPM_BUILD_ROOT%{_libdir}/powerchute
install ups_adjust $RPM_BUILD_ROOT%{_libdir}/powerchute
install upsoff $RPM_BUILD_ROOT%{_libdir}/powerchute
install upswrite $RPM_BUILD_ROOT%{_libdir}/powerchute
install wall.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install what_os.sh $RPM_BUILD_ROOT%{_libdir}/powerchute
install pwrchute.uid $RPM_BUILD_ROOT/usr/X11R6/lib/X11/uid/

install pwrchute.ad $RPM_BUILD_ROOT/usr/X11R6/lib/X11/app-defaults/pwrchute

ln -s /var/run/upsd.pid $RPM_BUILD_ROOT%{_libdir}/powerchute/
ln -s /var/run/bkupsd.pid $RPM_BUILD_ROOT%{_libdir}/powerchute/

gzip -9nf language.txt readme_apache

%pre
if ! id -g pwrchute > /dev/null 2>&1 ; then
	%{_sbindir}/groupadd -g 68 pwrchute
fi
if ! id -u pwrchute > /dev/null 2>&1 ; then
	%{_sbindir}/useradd -u 68 -g 68 -d /dev/null -s /bin/false -c "PowerChute Plus" pwrchute
fi

%post
/sbin/chkconfig --add upsd
if [ -f /var/lock/subsys/upsd ]; then
	/etc/rc.d/init.d/upsd restart 1>&2
else
	echo "Type \"/etc/rc.d/init.d/upsd start\" to start UPSd server" 1>&2
fi
cd %{_libdir}/powerchute
./machine_id
echo "You should run %{_libdir}/powerchute/Config.sh to configure PowerChute plus"
echo "Remember to set the password for pwrchute account"
	
%preun
if [ "$1" = "0" ]; then
	if [ -f /var/lock/subsys/upsd ]; then
		/etc/rc.d/init.d/upsd stop 1>&2
	fi
	/sbin/chkconfig --del upsd
fi

%postun
if [ "$1" = "0" ]; then
	%{_sbindir}/userdel pwrchute
	%{_sbindir}/groupdel pwrchute
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%doc help/* apachesh.pdf language.txt.gz readme_apache.gz pclinxug.pdf
%attr(754,root,root) /etc/rc.d/init.d/upsd
%config(noreplace) %verify(not size mtime md5) /etc/powerchute.ini
%attr(755,root,root) %{_sbindir}/upsd
%attr(755,root,root) %{_libdir}/powerchute/Config.sh
%attr(755,root,root) %{_libdir}/powerchute/_xpwrchute
%attr(755,root,root) %{_libdir}/powerchute/addpage.sh
%attr(755,root,root) %{_libdir}/powerchute/apacheshut
%attr(755,root,root) %{_libdir}/powerchute/bkupsd
%attr(755,root,root) %{_libdir}/powerchute/dialpager.sh
%attr(755,root,root) %{_libdir}/powerchute/killbk.sh
%attr(755,root,root) %{_libdir}/powerchute/killpc.sh
%attr(755,root,root) %{_libdir}/powerchute/machine_id
%attr(755,root,root) %{_libdir}/powerchute/mailer.sh
%attr(755,root,root) %{_libdir}/powerchute/notifier.sh
%attr(755,root,root) %{_libdir}/powerchute/pcshut.sh
%attr(755,root,root) %{_libdir}/powerchute/portcheck
%attr(755,root,root) %{_libdir}/powerchute/ttycheck
%attr(755,root,root) %{_libdir}/powerchute/ups_adjust
%attr(755,root,root) %{_libdir}/powerchute/upsoff
%attr(755,root,root) %{_libdir}/powerchute/upswrite
%attr(755,root,root) %{_libdir}/powerchute/wall.sh
%attr(755,root,root) %{_libdir}/powerchute/what_os.sh
%{_libdir}/powerchute/powerchute.ini
%{_libdir}/powerchute/powerchute.ini_templ
%attr(755,root,root) /usr/X11R6/bin/xpowerchute
/usr/X11R6/lib/X11/app-defaults/*
/usr/X11R6/lib/X11/uid/*
%config(noreplace) %verify(not size mtime md5) %{_libdir}/powerchute/upsd.pid
%config(noreplace) %verify(not size mtime md5) %{_libdir}/powerchute/bkupsd.pid
