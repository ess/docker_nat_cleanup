# Docker NAT Cleanup #

At present (docker-1.7.1), when Docker crashes, it doesn't seem to always clean up the iptables rules that it generated for the previous run. This often means that the new containers are not reachable via the public NAT'd port.

This (somewhat naievly) attempts to clean that up, given the number of a port that has been identified as misbehaving.

## Usage ##

`/path/to/docker_nat_cleanup PORT_NUMBER`

## Rationale ##

The script basically does this:

1. Grab the Docker NAT rules for the given port. If there is only one, we stop here, because you're not experiencing the problem that this script is designed to rectify.
2. Treat the first target IP as from the previous step as the "bad IP."
3. Grab all of the NAT rules for the bad IP.
4. Grab all of the filtering rules for the bad IP.
5. Delete the rules identified in previous steps.

If your current containers are still unreachable after this, one of the following is true:

* You're not experiencing the "stale Docker NAT rules" problem
* Docker didn't catch its stale rules more than once, and you can try the script again
