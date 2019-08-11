{
    "company": {
        "email": "derrick@tidepool.org"
    },
    "github": {
        "account": "tidepool-org",
        "user": "derrickburns",
        "token": ""
    },
    "cluster": {
        "repo": {
            "directory": "/Users/derrickburns/go/src/github.com/tidepool-org",
            "name": "",
            "branch": "master"
        },
        "eks": {
            "iam": {
                "administrators": [
                    "derrickburns-cli",
                    "lennartgoedhard-cli",
                    "benderr-cli"
                ]
            },
            "configFile": "",
            "kubeconfig": "",
            "name": "shared",
            "k8sVersion": "1.13",
            "region": "us-west-2",
            "cidr": "10.44.0.0/16",
            "nodegroup": {
                "instanceType": "m4.large",
                "desiredCapacity": 3,
                "minSize": 1,
                "maxSize": 10
            }
        },
        "logLevel": "debug",
        "mesh": {
            "name": "linkerd",
            "enabled": false
        },
        "gateway": {
            "proxy": {
                "name": "gateway-proxy-v2",
                "namespace": "gloo-system"
            }
        },
        "third-party-services": {
            "sumologic": {
                "enabled": false,
                "secret": {
                    "CollectorUrl": ""
                }
            },
            "datadog": {
                "enabled": false,
                "secret": {
                    "APIKey": "",
                    "AppKey": ""
                }
            },
            "fluxcloud": {
                "enabled": false,
                "secret": {
                    "url": ""
                }
            },
            "externalDNS": {
                "enabled": false,
                "hostnames": []
            }
        }
    },
    "environments": {
        "default": {
            "gitops": {
                "branch": "develop"
            },
            "secrets": {
                "src": "helm",
                "dest": "awsSecretsManager",
                "operation": "upsert"
            },
            "global": {
                "namespace": {
                    "create": false
                },
                "hpa": {
                    "maxReplicas": 10,
                    "minReplicas": 1,
                    "targetCPUUtilizationPercentage": 50
                },
                "hosts": {
                    "default": {
                        "protocol": "https"
                    },
                    "http": {
                        "enabled": false
                    },
                    "https": {
                        "enabled": true,
                        "port": "433",
                        "dnsNames": [
                            "default.tidepool.org"
                        ],
                        "certificateIssuer": "letsencrypt-staging"
                    }
                },
                "store": {
                    "type": "s3"
                },
                "nodeEnvironment": "production",
                "resources": {
                    "limits": {
                        "cpu": "200m",
                        "memory": "128Mi"
                    },
                    "requests": {
                        "cpu": "50m",
                        "memory": "32Mi"
                    }
                },
                "securityContext": {
                    "allowPrivilegeEscalation": false,
                    "runAsNonRoot": true
                }
            },
            "sharedInternalSecrets": {
                "userdata": {
                    "secret": {
                        "UserPasswordSalt": "",
                        "UserIdSalt": "",
                        "GroupIdEncryptionKey": ""
                    }
                },
                "server": {
                    "secret": {
                        "ServiceAuth": ""
                    }
                },
                "mongo": {
                    "secret": {
                        "Scheme": "mongodb",
                        "Addresses": "cluster0-shard-00-01-hu2cn.mongodb.net:27017,cluster0-shard-00-00-hu2cn.mongodb.net:27017,cluster0-shard-00-02-hu2cn.mongodb.net:27017",
                        "Username": "derrickburns",
                        "Tls": "true",
                        "Password": "",
                        "Database": ""
                    }
                }
            },
            "tidepoolServices": {
                "blip": {
                    "deployment": {
                        "image": "tidepool/blip:release-1.23.0-264f7ad48eb7d8099b00dce07fa8576f7068d0a0"
                    }
                },
                "export": {
                    "enabled": true,
                    "secret": {
                        "SessionEncryptionKey": ""
                    },
                    "deployment": {
                        "image": "tidepool/export:develop-c67e1425a4f6eb4c3f70f95284a24899a9ff986f"
                    },
                    "service": {
                        "port": 9300
                    }
                },
                "gatekeeper": {
                    "deployment": {
                        "image": "tidepool/gatekeeper:develop-6a0e3e6d83552ce378b21d76354973dcb95c9fa1"
                    },
                    "service": {
                        "port": 9123
                    }
                },
                "messageapi": {
                    "deployment": {
                        "image": "tidepool/message-api:develop-448835b6be0c27185e487f582f9b47a784aa781f",
                        "env": {
                            "window": 21
                        }
                    },
                    "service": {
                        "port": 9119
                    }
                },
                "seagull": {
                    "deployment": {
                        "image": "tidepool/seagull:develop-b06870d3752afede7da24116763fd5a161b84da0"
                    },
                    "service": {
                        "port": 9120
                    }
                },
                "highwater": {
                    "deployment": {
                        "image": "tidepool/highwater:develop-aaefb43df9a132f6c012f7216952e8650e6f6b4a"
                    },
                    "secret": {
                        "UserIdSalt": ""
                    },
                    "service": {
                        "port": 9191
                    }
                },
                "auth": {
                    "secret": {
                        "ServiceAuth": ""
                    },
                    "deployment": {
                        "image": "tidepool/platform-auth:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80"
                    },
                    "service": {
                        "port": 9222
                    }
                },
                "blob": {
                    "secret": {
                        "ServiceAuth": ""
                    },
                    "service": {
                        "port": 9225
                    },
                    "deployment": {
                        "image": "tidepool/platform-blob:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80",
                        "env": {
                            "directory": "_data/blobs",
                            "prefix": "blobs"
                        }
                    }
                },
                "data": {
                    "secret": {
                        "ServiceAuth": ""
                    },
                    "service": {
                        "port": 9220
                    },
                    "deployment": {
                        "image": "tidepool/platform-data:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80"
                    }
                },
                "image": {
                    "secret": {
                        "ServiceAuth": ""
                    },
                    "service": {
                        "port": 9226
                    },
                    "deployment": {
                        "image": "tidepool/platform-image:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80",
                        "env": {
                            "directory": "_data/image",
                            "prefix": "images"
                        }
                    }
                },
                "notification": {
                    "secret": {
                        "ServiceAuth": ""
                    },
                    "service": {
                        "port": 9223
                    },
                    "deployment": {
                        "image": "tidepool/platform-notification:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80"
                    }
                },
                "task": {
                    "secret": {
                        "ServiceAuth": ""
                    },
                    "service": {
                        "port": 9224
                    },
                    "deployment": {
                        "image": "tidepool/platform-task:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80"
                    }
                },
                "user": {
                    "secret": {
                        "ServiceAuth": ""
                    },
                    "deployment": {
                        "image": "tidepool/platform-user:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80"
                    },
                    "service": {
                        "port": 9221
                    }
                },
                "tools": {
                    "enabled": true,
                    "deployment": {
                        "image": "tidepool/platform-tools:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80"
                    }
                },
                "shoreline": {
                    "configmap": {
                        "ClinicDemoUserId": ""
                    },
                    "secret": {
                        "ServiceAuth": "",
                        "UserLongTermKey": null,
                        "UserMailVerification": "",
                        "UserPasswordSalt": "",
                        "ClinicDemoUserId": ""
                    },
                    "deployment": {
                        "image": "tidepool/shoreline:develop-169c2a61c33d31bb185663cf0033fd2a364d3492"
                    },
                    "service": {
                        "port": 9107
                    }
                },
                "tidewhisperer": {
                    "deployment": {
                        "image": "tidepool/tide-whisperer:develop-3d9d8e6b3417c70679ec43420f2a5e4a69cf9098"
                    },
                    "service": {
                        "port": 9127
                    }
                },
                "jellyfish": {
                    "enabled": true,
                    "deployment": {
                        "image": "tidepool/jellyfish:develop-2ed5f94724055c613be193cfbbbc3a8e41919de1"
                    },
                    "service": {
                        "port": 9122
                    }
                },
                "migrations": {
                    "enabled": true,
                    "deployment": {
                        "image": "tidepool/platform-migrations:develop-e95a3af6080aab5b845d1531015f0c5fd7134f80"
                    }
                },
                "hydrophone": {
                    "deployment": {
                        "image": "tidepool/hydrophone:develop-0683c6ba2c75ffd21ac01cd577acfeaf5cd0ef8f",
                        "env": {
                            "fromAddress": "Tidepool <noreply@tidepool.org>",
                            "bucket": ""
                        }
                    },
                    "service": {
                        "port": 9157
                    }
                }
            },
            "thirdPartyInternalServices": {
                "nosqlclient": {
                    "enabled": false,
                    "deployment": {
                        "image": "tidepool/nosqlclient:2.3.2"
                    },
                    "service": {
                        "port": 3000
                    }
                },
                "gloo": {
                    "enabled": true,
                    "settings": {
                        "create": true
                    },
                    "discovery": {
                        "fdsMode": "WHITELIST"
                    },
                    "namespace": {
                        "create": false
                    },
                    "gatewayProxies": {
                        "gatewayProxyV2": {
                            "service": {
                                "httpPort": 8080,
                                "type": "ClusterIP"
                            }
                        }
                    }
                },
                "mongodb": {
                    "enabled": true,
                    "image": {
                        "tag": "3.6"
                    },
                    "persistence": {
                        "enabled": false
                    },
                    "fullnameOverride": "mongodb"
                }
            },
            "externallySharedSecrets": {
                "dexcom": {
                    "enabled": false,
                    "secret": {
                        "ClientId": "",
                        "ClientSecret": "",
                        "StateSalt": ""
                    }
                },
                "carelink": {
                    "enabled": false,
                    "secret": {
                        "CareLinkSalt": ""
                    }
                },
                "mailchimp": {
                    "enabled": false,
                    "secret": {
                        "MailchimpClinicLists": "",
                        "MailchimpURL": "",
                        "MailchimpPersonalLists": "",
                        "MailchimpApiKey": ""
                    }
                },
                "kissmetrics": {
                    "enabled": false,
                    "secret": {
                        "KissmetricsAPIKey": "",
                        "KissmetricsToken": "",
                        "UCSFKissmetricsAPIKey": "",
                        "UCSFWhitelist": ""
                    }
                }
            }
        }
    }
}