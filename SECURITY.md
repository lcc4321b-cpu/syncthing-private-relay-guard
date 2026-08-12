# Security Policy

This project intentionally excludes deployment-specific secrets and identities.

Before reporting a problem or publishing a fork, remove:

- relay tokens and discovery credentials;
- Syncthing API keys, certificates, and private keys;
- device IDs and private folder paths;
- public IP addresses, hostnames, usernames, and incident logs.

Do not open a public issue containing active credentials. Rotate any credential that was committed, even if the commit was later deleted.

