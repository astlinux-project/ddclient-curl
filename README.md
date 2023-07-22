
# ddclient-curl

Fork of ddclient using curl for network IO

Comprehensive IPv4/IPv6 framework by David Kerr

-------------------------------------------------------------------------------
DNS services currently supporting both IPv4 and IPv6 include:

    Cloudflare   - See https://www.cloudflare.com/ for details
    FreeDNS      - See https://freedns.afraid.org/ for details
    HE Free DNS  - See https://dns.he.net/ for details (Hurricane Electric)
    DuckDNS      - See https://www.duckdns.org/ for details
    IPv64        - See https://ipv64.net/ for details
    nsupdate     - See nsupdate(1) and ddns-confgen(8) for details

Additional DNS services supported as with ddclient 3.8.3:

- See https://github.com/wimpunk/ddclient/tree/v3.8.3 for details

-------------------------------------------------------------------------------
Requirements:

- An account from one of the supported DNS services

- Perl 5.014 or later
  * JSON::PP perl library for JSON support (Cloudflare)
  * Digest::SHA perl library for SHA1 support (FreeDNS)

- 'curl' from the libcurl package

- 'ip' from the iproute2 package (Linux)

-------------------------------------------------------------------------------

