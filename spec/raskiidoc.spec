Summary: RaskiiDoc Builder
Name: raskiidoc
Version: 0.9
Release: 1%{dist}
License: GPLv3
Group: Applications/System
URL: https://github.com/llicour/raskiidoc
Source: %{name}-%{version}.tar.gz

%description
%{summary}.

Summary: RaskiiDoc Builder
Requires: rubygem-rake
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%prep
%setup -n %{name}

%build

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__mkdir} -p $RPM_BUILD_ROOT/%_sbindir
%{__mkdir} -p $RPM_BUILD_ROOT/usr/share/raskiidoc
%{__mkdir} -p $RPM_BUILD_ROOT/etc/raskiidoc

%{__cp} -R ./Rakefile $RPM_BUILD_ROOT/usr/share/%{name}
%{__cp} -R .rake $RPM_BUILD_ROOT/usr/share/%{name}
#%{__cp} ./scripts/* $RPM_BUILD_ROOT/usr/sbin
install -m 0755 ./scripts/raskiidoc $RPM_BUILD_ROOT/%_sbindir/raskiidoc
%{__cp} ./conf/* $RPM_BUILD_ROOT/etc/raskiidoc

#create version file

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-) 
%config(noreplace) /etc/raskiidoc/*
/usr/sbin/raskiidoc
/usr/share/%{name}/*
/usr/share/%{name}/.rake/*

%doc

#%config /etc/raskiidoc/*
#%attr(0755,root,root) %dir /usr/share/%{name}
#%attr(0755,root,root) /usr/sbin/raskiidoc
#%attr(0644,root,root) %dir /etc/raskiidoc

%pre

%post

%preun

%postun

%changelog
