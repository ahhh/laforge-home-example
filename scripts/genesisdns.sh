#!/bin/bash

cat<<EOF > /etc/resolv.conf
# Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)
#     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

export DEBCONF_NONINTERACTIVE_SEEN=true
export DEBIAN_FRONTEND=noninteractive

apt -qy update > /dev/null 2>&1
apt -qy upgrade > /dev/null 2>&1

apt -y install bind9 bind9utils

cat<<EOF > /etc/bind/named.conf
options {
  directory "/var/cache/bind";

  forwarders {
    8.8.8.8;
  };

  allow-update {
    0.0.0.0/0;
  };

  recursion yes;
  allow-query {
    0.0.0.0/0;
  };

  dnssec-validation auto;

  auth-nxdomain no;
  listen-on-v6 { any; };
};

zone "." {
  type hint;
  file "/etc/bind/db.root";
};

zone "localhost" {
  type master;
  file "/etc/bind/db.local";
};

zone "127.in-addr.arpa" {
  type master;
  file "/etc/bind/db.127";
};

zone "0.in-addr.arpa" {
  type master;
  file "/etc/bind/db.0";
};

zone "255.in-addr.arpa" {
  type master;
  file "/etc/bind/db.255";
};

zone "{{ $.Competition.Domain }}" {
  type master;
  file "db.{{ $.Competition.Domain }}";
  allow-update {
    0.0.0.0/0;
  };
  allow-query {
    0.0.0.0/0;
  };
};

zone "admin.{{ $.Competition.Domain }}" {
  type forward;
  forwarders {
    8.8.8.8;
  };
};

zone "0.10.in-addr.arpa" {
  type master;
  file "db.0.10.in-addr.arpa";
  allow-update {
    0.0.0.0/0;
  };
  allow-query {
    0.0.0.0/0;
  };
};

EOF

cat<<'EOF' > /var/cache/bind/db.0.10.in-addr.arpa
$ORIGIN 0.10.in-addr.arpa.
$TTL 86400
@ IN  SOA {{ $.Host.Hostname }}.{{ $.Competition.Domain }}. administrators.{{ $.Competition.Domain }}. (
      2001062501 ; serial
      21600      ; refresh after 6 hours
      3600       ; retry after 1 hour
      604800     ; expire after 1 week
      86400 )    ; minimum TTL of 1 day
;
@ IN  NS  {{ $.Host.Hostname }}.{{ $.Competition.Domain }}.
{{- range $_, $netName := $.Environment.IncludedNetworks }}
{{- $net := index $.Environment.ResolvedNetworks $netName }}
{{- range $_, $hostName := $net.IncludedHosts }}
{{- $host := index $net.ResolvedHosts $hostName }}
{{- $hostIP := CalculateReversePTR $net $host }}
{{- $fqdn := printf "%s-%s%d.%s.%s." $host.Hostname $.Environment.Prefix $.PodID $net.Subdomain $.Competition.Domain }}
{{ $hostIP }} 300 IN PTR {{ $fqdn }}
{{- end }}
{{- end }}

EOF

cat<<'EOF' > /var/cache/bind/db.{{ $.Competition.Domain }}
$ORIGIN {{ $.Competition.Domain }}.
$TTL 300
@ IN  SOA  {{ $.Host.Hostname }}.{{ $.Competition.Domain }}. administrators.{{ $.Competition.Domain }}. (
      2001062502 ; serial
      21600      ; refresh after 6 hours
      3600       ; retry after 1 hour
      604800     ; expire after 1 week
      300 )    ; minimum TTL of 1 day
;
@ IN  NS   {{ $.Host.Hostname }}.{{ $.Competition.Domain }}.
{{ $.Host.Hostname }} 300 IN  A  10.0.254.250
admin 300 IN NS  ns-1075.awsdns-06.org.
admin 300 IN NS  ns-1814.awsdns-34.co.uk.
admin 300 IN NS  ns-37.awsdns-04.com.
admin 300 IN NS  ns-779.awsdns-33.net.
vdi   300 IN NS  ns-948.awsdns-54.net.
vdi   300 IN NS  ns-1613.awsdns-09.co.uk.
vdi   300 IN NS  ns-165.awsdns-20.com.
vdi   300 IN NS  ns-1087.awsdns-07.org.
{{- range $_, $netName := $.Environment.IncludedNetworks }}
{{- $net := index $.Environment.ResolvedNetworks $netName }}
{{- range $_, $hostName := $net.IncludedHosts }}
{{- $host := index $net.ResolvedHosts $hostName }}
{{- $hostIP := CustomIP $net.CIDR 0 $host.LastOctet }}
{{- $fqdn := printf "%s-%s%d.%s" $host.Hostname $.Environment.Prefix $.PodID $net.Subdomain }}
{{ $fqdn }} 300 IN A {{ $hostIP }}
{{- range $_, $cname := $host.ExternalCNAMEs }}
{{ $cname }} 300 IN CNAME {{ $fqdn }}
{{- end }}
{{- end }}
{{- end }}
EOF

service bind9 stop
service bind9 start

echo "Finished Configuring NS1"
