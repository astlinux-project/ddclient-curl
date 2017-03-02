#!/usr/bin/perl -w

##
## Get IPv6 global address given it's IPv4 address or hostname
##
## Usage: get-ipv6-from-ipv4 address|hostname
##
## Return IPv6 global address in stdout
##

use strict;
use warnings;

my $hostv4 = $ARGV[0];

sub usage {
  print STDERR "Usage: get-ipv6-from-ipv4 address|hostname\n";
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

# Add hostv4 entry to ARP table
`fping -c 1 $hostv4 >/dev/null 2>&1`;

my $arp = `arp -a $hostv4`;

my $mac = $1 if $arp =~ /^.*? at ([0-9a-fA-F:]+) /s;

my $int = $1 if $arp =~ /^.*? on ([0-9a-zA-Z.]+)/s;

if (!defined $mac || !defined $int) {
  error "No entry in ARP table for host: $hostv4";
}

my $ip_cmd = `ip -6 -o addr show dev $int scope global 2>/dev/null`;

my $srcv6 = $1 if $ip_cmd =~ /^.*? inet6 ([0-9a-fA-F:]+)\//s;

if (!defined $srcv6) {
  error "No IPv6 global address for interface: $int";
}

# fping6 "ff02::1" (All Nodes Address) with the global address source of the interface
`fping6 -I $int -c 2 -S $srcv6 ff02::1 >/dev/null 2>&1`;

# Wait for Neighbor Discovery to settle
sleep 5;

# Output the first IPv6 global address matching the MAC address
my $llhostv6;
my $hostv6;
$ip_cmd = `ip -6 neigh show dev $int`;
my @lines = split('\n', $ip_cmd);
foreach my $line (@lines) {
  if ($line =~ /^fe80::/i) {
    if ($line =~ /^([0-9a-f:]+) .*lladdr ${mac}/i) {
      $llhostv6 = $1;
    }
  } else {
    if ($line =~ /^([0-9a-f:]+) .*lladdr ${mac}/i) {
      $hostv6 = $1;
      last;
    }
  }
}
if (defined $hostv6) {
  print "$hostv6\n";
  exit 0;
} elsif (!defined $llhostv6) {
  exit 1;
}

# Generate the IPv6 EUI-64 format from the prefix and link-local host
my @p = split(':', $srcv6);
my @h = split(':', $llhostv6);
$hostv6 = join(':', $p[0], $p[1], $p[2], $p[3], $h[$#h-3], $h[$#h-2], $h[$#h-1], $h[$#h]);

# Try again with the IPv6 EUI-64 format
`fping6 -I $int -c 2 -S $srcv6 $hostv6 >/dev/null 2>&1`;

# Wait for Neighbor Discovery to settle
sleep 1;

# Output the first IPv6 global address matching the MAC address
undef $hostv6;
$ip_cmd = `ip -6 neigh show dev $int`;
@lines = split('\n', $ip_cmd);
foreach my $line (@lines) {
  if (!($line =~ /^fe80::/i)) {
    if ($line =~ /^([0-9a-f:]+) .*lladdr ${mac}/i) {
      $hostv6 = $1;
      last;
    }
  }
}
print "$hostv6\n" if defined $hostv6;
exit 0;
