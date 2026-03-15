#!/usr/bin/env bash
# Export Caddy's internal CA certificate for trusting on other devices.
# Caddy generates a root CA when using 'tls internal'. Install this
# certificate in your device's trust store to avoid browser warnings.

CA_CERT="/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt"

if [[ ! -r "$CA_CERT" ]]; then
	echo "Cannot read Caddy CA certificate at ${CA_CERT}"
	echo "Ensure Caddy has started at least once with 'tls internal'."
	echo "You may need to run this with sudo."
	exit 1
fi

if [[ "${1:-}" == "--copy" ]]; then
	dest="${2:-.}/caddy-root-ca.crt"
	cp "$CA_CERT" "$dest"
	echo "CA certificate copied to ${dest}"
else
	echo "# Caddy Internal CA Certificate"
	echo "# Install in your device's trust store to avoid browser warnings."
	echo ""
	cat "$CA_CERT"
	echo ""
	echo "Usage: trust-server-ca --copy [directory]"
fi
