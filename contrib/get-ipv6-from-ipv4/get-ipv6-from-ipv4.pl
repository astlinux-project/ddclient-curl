#!/usr/bin/perl -w

##
## Get IPv6 global address given it's IPv4 address or hostname
##
## Usage: get-ipv6-from-ipv4 address|hostname [gua|ula|lla|all]
##
## Return IPv6 global address in stdout
##

use strict;
use warnings;

my $hostv4 = $ARGV[0];

my $type = $ARGV[1];

sub usage {
  print STDERR "Usage: get-ipv6-from-ipv4 address|hostname [gua|ula|lla|all]\n";
  exit 1;
}

sub error {
  my $msg = shift || '';
  printf STDERR "get-ipv6-from-ipv4: %s\n", $msg;
  exit 1;
}

if (!defined $hostv4 || $hostv4 eq '') {
  usage;
}

if (!defined $type || ($type ne 'ula' && $type ne 'lla' && $type ne 'all')) {
  $type = 'gua';
}

# Add hostv4 entry to ARP table
`fping -4 -c 1 $hostv4 >/dev/null 2>&1`;

my $arp = `arp -a $hostv4`;

my $mac = $1 if $arp =~ /^.*? at ([0-9a-fA-F:]+) /s;

my $int = $1 if $arp =~ /^.*? on ([0-9a-zA-Z.]+)/s;

if (!defined $mac || !defined $int) {
  error "No entry in ARP table for host: $hostv4";
}

my $gua_srcv6;
my $ula_srcv6;
my $srcv6;
my $ipv6;
my $ip_cmd = `ip -6 -o addr show dev $int scope global 2>/dev/null`;
my @lines = split('\n', $ip_cmd);
foreach my $line (@lines) {
  if ($line =~ /^.* inet6 ([0-9a-fA-F:]+)\//) {
    $ipv6 = $1;
    if ($ipv6 =~ /^fd/i) {
      $ula_srcv6 = $ipv6 if !defined $ula_srcv6;
    } else {
      $gua_srcv6 = $ipv6 if !defined $gua_srcv6;
    }
  }
}
if ($type eq 'ula') {
  $srcv6 = $gua_srcv6 if defined $gua_srcv6;
  $srcv6 = $ula_srcv6 if defined $ula_srcv6;
} else {
  $srcv6 = $ula_srcv6 if defined $ula_srcv6;
  $srcv6 = $gua_srcv6 if defined $gua_srcv6;
}

if (!defined $srcv6) {
  error "No IPv6 global address for interface: $int";
}

# fping -6 "ff02::1" (All Nodes Address) with the global address source of the interface
`fping -6 -I $int -c 2 -S $srcv6 ff02::1 >/dev/null 2>&1`;

# Wait for Neighbor Discovery to settle
sleep 5;

# Output the first IPv6 global address matching the MAC address
my $gua_hostv6;
my $ula_hostv6;
my $lla_hostv6;
$ip_cmd = `ip -6 neigh show dev $int`;
@lines = split('\n', $ip_cmd);
foreach my $line (@lines) {
  if ($line =~ /^fe80::/i) {
    if ($line =~ /^([0-9a-f:]+) .*lladdr ${mac}/i) {
      $lla_hostv6 = $1 if !defined $lla_hostv6;
    }
  } else {
    if ($line =~ /^([0-9a-f:]+) .*lladdr ${mac}/i) {
      $ipv6 = $1;
      if ($ipv6 =~ /^fd/i) {
        $ula_hostv6 = $ipv6 if !defined $ula_hostv6;
      } else {
        $gua_hostv6 = $ipv6 if !defined $gua_hostv6;
      }
    }
  }
}
if (defined $gua_hostv6 && $type eq 'gua') {
  print "$gua_hostv6\n";
  exit 0;
} elsif (defined $ula_hostv6 && $type eq 'ula') {
  print "$ula_hostv6\n";
  exit 0;
} elsif (defined $lla_hostv6 && $type eq 'lla') {
  print "$lla_hostv6\n";
  exit 0;
}
if (!defined $lla_hostv6) {
  exit 1;
}

# Generate the IPv6 EUI-64 format from the prefix and link-local host
my @p = split(':', $srcv6);
my @h = split(':', $lla_hostv6);
$ipv6 = join(':', $p[0], $p[1], $p[2], $p[3], $h[$#h-3], $h[$#h-2], $h[$#h-1], $h[$#h]);

# Try again with the IPv6 EUI-64 format
`fping -6 -I $int -c 2 -S $srcv6 $ipv6 >/dev/null 2>&1`;

# Wait for Neighbor Discovery to settle
sleep 1;

# Output the first IPv6 global address matching the MAC address
undef $gua_hostv6;
undef $ula_hostv6;
$ip_cmd = `ip -6 neigh show dev $int`;
@lines = split('\n', $ip_cmd);
foreach my $line (@lines) {
  if (!($line =~ /^fe80::/i)) {
    if ($line =~ /^([0-9a-f:]+) .*lladdr ${mac}/i) {
      $ipv6 = $1;
      if ($ipv6 =~ /^fd/i) {
        $ula_hostv6 = $ipv6 if !defined $ula_hostv6;
      } else {
        $gua_hostv6 = $ipv6 if !defined $gua_hostv6;
      }
    }
  }
}
if ($type eq 'all') {
  print "$gua_hostv6\n" if defined $gua_hostv6;
  print "$ula_hostv6\n" if defined $ula_hostv6;
  print "$lla_hostv6\n" if defined $lla_hostv6;
  exit 0;
}
if (defined $gua_hostv6 && $type eq 'gua') {
  print "$gua_hostv6\n";
  exit 0;
} elsif (defined $ula_hostv6 && $type eq 'ula') {
  print "$ula_hostv6\n";
  exit 0;
}
exit 1;
