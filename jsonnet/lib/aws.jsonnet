local str = import "str.jsonnet";
local kube = import "kube.jsonnet";

{
  bucketName(config, env)::
    if std.objectHas(env.store, 'bucket') && env.store.bucket != ''
    then env.store.bucket
    else '%s-%s-%s-data' % [config.store.s3.bucketNamePrefix, config.cluster.name, env.name],

  role(config, name):: config.cluster.name + '-' + name + '-role',

  roleAnnotation(config, name):: {
    'iam.amazonaws.com/role': $.role(config, name),
  },

  permittedAnnotation(config, name):: {
    'iam.amazonaws.com/permitted': "%s-.*" % config.cluster.name 
  },

  cfObject(config, group, cfKind):: {
    local this = self,
    apiVersion:: '2012-10-17',
    kind:: cfKind,
    metadata:: {
      name:: group.name,
    },

    values:: {
      Type: this.kind,
    },
    [self.iamName(config, group, cfKind)]: this.values,
  },

  kindToName(cfKind):: std.strReplace(cfKind, "::", "-"),

  iamName(config, group, cfKind):: str.capitalize(str.camelCase(group.name) + str.camelCase($.kindToName(cfKind))),

  iamManagedPolicy(config, group):: $.cfObject(config, group, 'AWS::IAM::ManagedPolicy') {
    local this = self,
    values+:: {
      Properties: {
        PolicyDocument: {
          Version: this.apiVersion,
        },
      },
    },
  },

   helmrelease(config, group):: kube.helmrelease(config, group) {
    spec: {
      values+: 
        if std.objectHas(group, 'iam') && group.iam.create 
        then { podAnnotations: $.roleAnnotation(config, group.name) } 
        else {}
    },
  },

  namespace(config, group):: kube.namespace(config, group) {
    metadata+: {
      annotations+: if std.objectHas(group, 'iam') && group.iam.create then $.permittedAnnotation(config, group.namespace.name) else {},
    },
  },

  secret(config, group, defaultNamespace="default"):: $.cfObject(config, group, 'AWS::SecretsManager::Secret') {
    local this = self,
    values+:: {
      Properties: {
        Name: group.secret.name,
        SecretString: std.manifestJson(this.data),
        Tags: [
        {
            Key: "Cluster",
            Value: config.cluster.name
        },
        {
            Key: "Namespace",
            Value: kube.namespaceName(group, defaultNamespace)
        }
        ]
      }
    },
    data_:: if std.objectHas(group.secret, 'data_') then group.secret.data_ else {},
    data: { [k]: std.base64(this.data_[k]) for k in std.objectFields(this.data_) },
  },

  loggedS3Bucket(config,group):: $.cfObject(config, group, 'AWS::S3::Bucket') {
    values+:: {
      local name = bucketName(config,group),
      Condition: "EC2RoleVersion1",
      DeletionPolicy: "Retain",
      Properties: {
        AccessControl: "Private",
        BucketName: name,
        LoggingConfiguration: {
          LogFilePrefix: 'AWSLogs/%s/S3/%s/' % [ config.cluster.eks.accountNumber, name ]
        },
        Tags:  [
          {
            Key: "Name",
            Value: "%s-%s-DataBucket" % [ config.cluster.eks.name, group.name ]
          }, {
            Key: "Tidepool-Env",
            Value: {
              'Fn::GetAtt': group.name
            }
          }, {
            Key: "Tidepool-Stack",
            Value: {
              Ref: "AWS::StackName"
            }
          }
        ]
      }
    }
  },

  publicRoute(config,group):: $.cfObject(config, group, 'AWS::EC2::Route') {
    values+:: {
      DependsOn: "OpsVPCPeeringConnection",
      Properties: {
        DestinationCidrBlock: {
          'Fn::Sub': '${OpsNetStackOutputs.IpPrefix}.0.0/16'
        },
        VpcPeeringConnectionId: {
          Ref: "OpsVPCPeeringConnection"
        },
        RouteTableId: {
          'Fn::GetAtt': "EnvNetStackOutputs.PublicRouteTableId" 
        },
      }
    }
  },

  peeringConnection(config,group):: $.cfObject(config, group, 'AWS::EC2::VPCPeeringConnection') {
    values+:: {
      Condition: "EC2RoleVersion1",
      DeletionPolicy: "Retain",
      Properties: {
        VpcId: {
          'Fn::GetAtt': "EnvNetStackOutputs.VPCId" // XXX - get this from eksctl
        },
        PeerVpcId: {
          'Fn::GetAtt': "OpsNetStackOutputs.VPCId" // XXX
        },
        Tags: [
          {
            Key: "Name",
            Value: "%s-%s-DBPeeringConnection" % [ config.cluster.eks.name, group.name ]
          }, {
            Key: "Tidepool-Env",
            Value: {
              'Fn::GetAtt': group.name
            }
          }, {
            Key: "Tidepool-Stack",
            Value: {
              Ref: "AWS::StackName"
            }
          }
        ]
      }
    }
  },

  iamRole(config, group):: $.cfObject(config, group, 'AWS::IAM::Role') {
    local this = self,
    values+:: {
      Properties: {
        RoleName: '%s-%s-role' % [config.cluster.name, group.name],
        ManagedPolicyArns: [{
          Ref: $.iamName(config, group, 'AWS::IAM::ManagedPolicy'),
        }],
        AssumeRolePolicyDocument: {
          Version: this.apiVersion,
          Statement: [
            {
              Action: 'sts:AssumeRole',
              Effect: 'Allow',
              Principal: {
                Service: 'ec2.amazonaws.com',
              },
            },
            {
              Action: 'sts:AssumeRole',
              Effect: 'Allow',
              Principal: {
                AWS: {
                  'Fn::GetAtt': [
                    $.iamName(config, config.groups.kiam, 'AWS::IAM::Role'),
                    'Arn',
                  ],
                },
              },
            },
          ],
        },
      },
    },
  },
}
