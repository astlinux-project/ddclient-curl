
# get-ipv6-from-ipv4.pl

A script designed to obtain the IPv6 global address from a neighboring device,
given it's IPv4 address or hostname.

    Usage: get-ipv6-from-ipv4 address|hostname [gua|ula|lla|all]

Returns IPv6 global address in stdout, if any, or specific IPv6 address type.

Optional second argument defaults to 'gua'.

Example usage in ddclient:

    usev6=cmd, cmdv6=/mnt/kd/bin/get-ipv6-from-ipv4.pl <local_ipv4>

Be sure to rename the script as desired, and make it executable.

