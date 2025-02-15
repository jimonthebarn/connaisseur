#!/usr/bin/expect

spawn notary init docker.io/securesystemsengineering/testimage --publish -c ./tests/data/notary_service_container/config/client_config.json -s https://notary.server:4443 -D
expect "Enter passphrase for new root key with ID*\r"
send -- "0123456789\r"
expect "Repeat passphrase for new root key with ID*\r"
send -- "0123456789\r"
expect "Enter passphrase for new targets key with ID*\r"
send -- "0123456789\r"
expect "Repeat passphrase for new targets key with ID*\r"
send -- "0123456789\r"
expect "Enter passphrase for new snapshot key with ID*\r"
send -- "0123456789\r"
expect "Repeat passphrase for new snapshot key with ID*\r"
send -- "0123456789\r"
expect eof
