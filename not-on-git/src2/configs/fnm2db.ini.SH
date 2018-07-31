#
# global config file -- parameters from db
#
[globals]
customerid              = ${uuid_customerid}
fastnetmoninstanceid    = ${uuid_fastnetmoninstanceid}
administratorid         = ${uuid_administratorid}
uuid                    = ${uuid}

# discard | rate-limit 9600 | accept
mode                    = ${mode}

# minutes to block/ratelimit/... in minutes (approximately)
blocktime               = ${blocktime}

[update]
# Send rules with sftp to user@server within sftp_timeout seconds
# using pubkey / privkey
server                  = 172.22.86.10
user                    = newrules
sftp_timeout            = 10
pubkey                  = /opt/i2dps/etc/ssh/id_ed25519.pub
privkey                 = /opt/i2dps/etc/ssh/id_ed25519
