### Start new `dev` `db` instance in `mongo migration VPC`

### Configure Networking
* Add internet gateway and routes to 0.0.0.0/0
* associate subnets (public)
* associate new Elastic IP with instance and note address
* whitelist Mongo DB ranges and self ip address for testing/migration
> security groups should contain permit rules for TCP/27017 for the following hosts:
```
35.167.231.51/32
35.165.213.202/32
54.203.84.230/32
54.203.82.184/32
```

### Remove mongo backup (for good measure and to prevent and inadvertant backup) and tidepool configuration cron job or it may overwrite any config changes for this temporary instance

```sh
rm /etc/cron.d/tidepool-configuration
rm /etc/cron.d/mongo-backup
```

### Update Mongo to 3.4 on Trusty Tahr 

```sh
$ sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6

$ echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.4.list

$ sudo apt-get update
$ sudo apt-get install -y mongodb-org

# upgrade local tools and other packages like mongo-client
$ sudo apt-get upgrade
```

### shutdown Mongo and update configuration
`sudo service mongodb stop`

### Convert configuration to replica set 

1. Remove old files:
$ sudo rm -rf /mnt/mongodb/*

1. add a replica set directory for new `rs0`

$ sudo mkdir /mnt/mongodb/rs0-0

3. Add the following to /etc/mongod.conf:
```json
# Replication
replication:
  replSetName: rs0
```
 4. Modify /etc/init.d/mongod to remove the replset commmands since I didn't understand them at the time. Will look into this further.

```sh
#REPLSETNAME="`/bin/echo "${AWS_USER_DATA}" | /usr/bin/jq -r '.mongodb.replication.replsetname // empty'`"

#/bin/sed -i '/^\(replication\|  replSetName\):.*/d' /etc/mongod.conf
#if [ -n "$REPLSETNAME" ]; then
#  /bin/echo "replication:" >> /etc/mongod.conf || { log_failure_msg "Failure starting mongod" && exit 1; }
#  /bin/echo "  replSetName: ${REPLSETNAME}" >> /etc/mongod.conf || { log_failure_msg "Failure starting mongod" && exit 1; }
#fi
```

5. Restart mongodb

6. Connect to mongo and add the `tidepooladmin` user and grant permissions:

```sh
$ mongo
rs0:PRIMARY> use admin
switched to db admin
```

**** paste the following:

```json
db.createUser(
  {
    user: "tidepooladmin",
    pwd: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase", "clusterMonitor", "backup" ]
  }
)
```

7. Validate user creation:

- validate user 

```json
rs0:PRIMARY> db.getUser("admin")
null
rs0:PRIMARY> db.getUser("tidepooladmin")
{
	"_id" : "admin.tidepooladmin",
	"user" : "tidepooladmin",
	"db" : "admin",
	"roles" : [
		{
			"role" : "userAdminAnyDatabase",
			"db" : "admin"
		},
		{
			"role" : "readWriteAnyDatabase",
			"db" : "admin"
		},
		{
			"role" : "clusterMonitor",
			"db" : "admin"
		},
		{
			"role" : "backup",
			"db" : "admin"
		}
	]
}
```
8. Add Authorization to Mongo in /etc/mongod.conf and restart mongo

```
# Security
security:
  authorization: enabled
```

> I ended up needing to disable SSL to get the Atlas migration to occur, it flat out wouldn't connect for anything. I ruled out everything else I could before consulting with Tapani and moving forward, given the nature of the data.
 
#### CA file for SSL auth:

```txt
-----BEGIN CERTIFICATE-----
MIIFxTCCA62gAwIBAgIJAO6u9dLw+ZbXMA0GCSqGSIb3DQEBCwUAMHkxCzAJBgNV
BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRIwEAYDVQQHDAlQYWxvIEFsdG8x
GTAXBgNVBAoMEFRpZGVwb29sIFByb2plY3QxJjAkBgNVBAMMHWRiLTIuZGV2LnBy
aXZhdGUudGlkZXBvb2wub3JnMB4XDTE5MDYyMTE4NTM1NloXDTI0MDYxOTE4NTM1
NloweTELMAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExEjAQBgNVBAcM
CVBhbG8gQWx0bzEZMBcGA1UECgwQVGlkZXBvb2wgUHJvamVjdDEmMCQGA1UEAwwd
ZGItMi5kZXYucHJpdmF0ZS50aWRlcG9vbC5vcmcwggIiMA0GCSqGSIb3DQEBAQUA
A4ICDwAwggIKAoICAQDpZzRMr/DtG3QhJG30mHPQh1ikDZKj9blKd0GBBGPYYD1B
Q/zCnOxnzksEjb5frohY++XsiDBrQjt2ouOtk6wAb9mM0DPZXnnEmNQMmVTugBH+
lBpG0TUVys7PGCEuxYTLnoh3nPTVCgLKJEWGV4IyaHNPvbCmUKL2nthQFNeAb1Ew
QebwX9/gOql1IjXBtCCvg67f8Sk2/oNM/ucneD1Na1dBm5kDKRX3Vzu6LjNI6GhQ
djxt1WLqxSDq3rdmP6dBHg7yEGkmM5Vn99omq27kbUAWR1ypWV5TzU5lbTubsmwk
7/DMAmsvI4k3kM7GUmUe7J73JlJ0inlaHMSJIlxLw175u0fAMkV+bGMOczvmy+r0
0t627Qdhtn1lDBly0oJXEDwpxslGIMBwV3XKj3Db3Wgpd0ElCcTNZehTTXkAQzBr
I+hm4/gbr3jIF7UUh/HRipK1NPdl8Vs01dS75UDbzUSWq+hkmqwHPzMlFQjgxZ5m
GuFtohiJhiCAnLXHdEEUdir755DvEkY5qkZAVxuSnl2OmZNFc4U48afiRjIRqcJS
t54OULkWICAjhtvWGl0HVpKonXMS6nItv4CP7usqmdcASHaD+BJ9yZ8vtZHHvIrL
A5TLL2NaDKkYjjHzjrUn8oRduQCyfRohgmHhd5J249XC4Bb4WHnJKAsh6eNtxwID
AQABo1AwTjAdBgNVHQ4EFgQUtSUmNy2KCz5QLAnHq1ylQu/xKXowHwYDVR0jBBgw
FoAUtSUmNy2KCz5QLAnHq1ylQu/xKXowDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0B
AQsFAAOCAgEAviLPKhW3NUCK4PWwPgkVzymE9cuF3KqfrE9oc25apfoywbLw4kwH
HjfEJxRkrSvsClM2ujD88wPeamnCtGjWamCfceY/YQaP0It8Fk1tqhrwTn1iBBRF
4FsMvf6KOcIHa93NrlDey1iDjwxZdT7+ZTxaEbOZcDoVDGZEQkVA5PAooCcpW/aG
+LRKFR2iYjX2b5XdBSH4zCYPbNn9riUPisxnakeQP6zUrNVPEddjTYbmKIY9663K
n5/HGbFQvF8QKHA8GnAfcJIkCujxUV+fKG5J8Gg4ipMtjoeeDWrhigSu/ebin32c
URARq5QdT26YWxLbfX/+QF9xuEirYolDwCWrpuRByOfBWnlPpqRFmlXk5KsQeTve
rvTxdjczD73v9Xgz3bXF+NGwToxOwD37rA0B+TAeteW9v26wWZNynFL3GlBIVho/
o8lY1fn4F0CZ0Y9d42iEZzTKVt4nH6bEI6kcgUGkOMHtg4nRRFLZzt/VMQ2WUGYP
oSnwC0fH9pDQs7zdUE1GEy5zf8dlYfcID7SxaDGsVlYoWZo5smT8tUb/Oq6xA6rR
H0/HvDI8M3WFfF6vSjW2ydy9RJ7wrOiS5WMiU8L55VsY7gnXLj6cGnM0Djk5zoEO
48f+gwffZDTomL4Gifv3xBXY/wo8AgiTEYDvsbDJ0DqfvhldbL3Fc64=
-----END CERTIFICATE-----
```

### new Mongo Replica Set in MongoDB Atlas

* connection string for MongoDB Atlas:

```sh 
mongodb://<username>:<password>@cluster0-shard-00-00-hu2cn.mongodb.net:27017,cluster0-shard-00-01-hu2cn.mongodb.net:27017,cluster0-shard-00-02-hu2cn.mongodb.net:27017/<DATABASE>?ssl=true&replicaSet=Cluster0-shard-0&authSource=admin&w=majority
```

### Mongo Security

- No users are permitted into the cluster by default
- No ip addresses are permitted into the cluster by default
- Both are needed for a successful connection

### AWS peering 

- suggest we only connect over AWS Peering wherever possible
- negotiating a CIDR range change with Derrick's `qae` cluster due to ip overlap with Atlas range of `192.168.248.0/21` 

### AWS IAM policy for mongo-kms IAM user:
> the rights can probably be restricted substantially, maybe everything but `encrypt` and `decrypt` can be removed.


```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "kms:GetParametersForImport",
                "kms:Decrypt",
                "kms:ListKeyPolicies",
                "kms:Encrypt",
                "kms:GetKeyRotationStatus",
                "kms:ListRetirableGrants",
                "kms:GetKeyPolicy",
                "kms:DescribeKey",
                "kms:ListResourceTags",
                "kms:ListGrants"
            ],
            "Resource": "arn:aws:kms:us-west-2:118346523422:key/91f3dada-d983-4234-87f2-4cb21b056dff"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "kms:DescribeCustomKeyStores",
                "kms:ListKeys",
                "kms:ListAliases"
            ],
            "Resource": "*"
        }
    ]
}
```