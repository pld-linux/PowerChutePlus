Summary:	UPS management software for APC UPS models
Summary(pl.UTF-8):   Oprogramowanie do obsługi UPS-ów APC
Name:		PowerChutePlus
Version:	4.5.3
Release:	1
License:	(c) 1999 APC, inc.
Group:		Applications/System
Source0:	ftp://ftp.apcc.com/apc/public/software/unix/linux/pcplus/453/pcplus_453_caldera.tar
# Source0-md5:	5eb99efd5561694b9f692aa713bd974d
Source1:	ftp://ftp.apcc.com/apc/public/software/unix/linux/pcplus/453/pc453ug.pdf
# Source1-md5:	0c2a621adcad8fdcb6064ed3cb042711
Source2:	upsd.init
Source3:	%{name}-xpowerchute.sh
Source4:	%{name}-Config.sh
Source5:	%{name}-powerchute.ini
Source6:	%{name}-powerchute.ini_templ
Source7:	ftp://ftp.apcc.com/apc/public/software/unix/linux/pcplus/settings.pdf
# Source7-md5:	c69abad141a836fd12ced0cc39049dc6
Patch0:		%{name}-fix-sh.patch
BuildRequires:	rpmbuild(macros) >= 1.268
Requires(post,preun):	/sbin/chkconfig
Requires(postun):	/usr/sbin/groupdel
Requires(postun):	/usr/sbin/userdel
Requires(pre):	/bin/id
Requires(pre):	/usr/bin/getgid
Requires(pre):	/usr/sbin/groupadd
Requires(pre):	/usr/sbin/useradd
Requires:	rc-scripts
Provides:	group(pwrchute)
Provides:	user(pwrchute)
ExclusiveArch:	%{ix86}
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
This program allows users to safely shut down their system in response
to power failures and other power events. It also allows users to
configure and manage UPS models.

Please note that %{_libdir}/powerchute/Config.sh should be run in order
to configure PowerChute plus.

%description -l pl.UTF-8
Ten program pozwala użytkownikom bezpiecznie wyłączyć system w
przypadku awarii zasilania. Pozwala także na skonfigurowanie UPS.

Uwaga: aby skonfigurować PowerChute Plus należy uruchomić
/usr/lib/powerchute/Config.sh .

%prep
%setup -q -c
for i in BI_LINUX CI_LINUX COMMON FI_LINUX HELP; do
	tar xf $i
done
%patch0 -p1

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT{%{_sbindir},%{_libdir}/powerchute} \
	$RPM_BUILD_ROOT/etc/rc.d/init.d \
	$RPM_BUILD_ROOT%{_prefix}/X11R6/{bin,lib/X11/{app-defaults,uid}}

install %{SOURCE1} .
install %{SOURCE7} .
install %{SOURCE2} $RPM_BUILD_ROOT/etc/rc.d/init.d/upsd
install %{SOURCE3} $RPM_BUILD_ROOT%{_prefix}/X11R6/bin/xpowerchute
install %{SOURCE4} $RPM_BUILD_ROOT%{_libdir}/powerchute/Config.sh
install %{SOURCE6} $RPM_BUILD_ROOT%{_libdir}/powerchute/powerchute.ini_templ
install %{SOURCE5} $RPM_BUILD_ROOT%{_sysconfdir}/powerchute.ini

ln -sf %{_sysconfdir}/powerchute.ini $RPM_BUILD_ROOT%{_libdir}/powerchute

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
install pwrchute.uid $RPM_BUILD_ROOT%{_prefix}/X11R6/lib/X11/uid

install pwrchute.ad $RPM_BUILD_ROOT%{_prefix}/X11R6/lib/X11/app-defaults/pwrchute

ln -sf /var/run/upsd.pid $RPM_BUILD_ROOT%{_libdir}/powerchute
ln -sf /var/run/bkupsd.pid $RPM_BUILD_ROOT%{_libdir}/powerchute

%clean
rm -rf $RPM_BUILD_ROOT

%pre
%groupadd -g 68 pwrchute
%useradd -u 68 -g 68 -d /usr/share/empty -s /bin/false -c "PowerChute Plus" pwrchute

%post
/sbin/chkconfig --add upsd
%service upsd restart "UPSd server"
cd %{_libdir}/powerchute
./machine_id
echo "You should run %{_libdir}/powerchute/Config.sh to configure PowerChute plus"
echo "Remember to set the password for pwrchute account"

%preun
if [ "$1" = "0" ]; then
	%service upsd stop
	/sbin/chkconfig --del upsd
fi

%postun
if [ "$1" = "0" ]; then
	%userremove pwrchute
	%groupremove pwrchute
fi

%files
%defattr(644,root,root,755)
%doc help/* apachesh.pdf language.txt readme_apache pc453ug.pdf settings.pdf
%attr(754,root,root) /etc/rc.d/init.d/upsd
%attr(640,root,pwrchute) %config(noreplace) %verify(not md5 mtime size) %{_sysconfdir}/powerchute.ini
%attr(755,root,root) %{_sbindir}/upsd
%dir %{_libdir}/powerchute
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
%attr(755,root,root) %{_prefix}/X11R6/bin/xpowerchute
%{_prefix}/X11R6/lib/X11/app-defaults/*
%{_prefix}/X11R6/lib/X11/uid/*
%config(noreplace) %verify(not md5 mtime size) %{_libdir}/powerchute/upsd.pid
%config(noreplace) %verify(not md5 mtime size) %{_libdir}/powerchute/bkupsd.pid
