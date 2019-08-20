local str = import "str.jsonnet";

{
  bucketName(config, env)::
    if std.objectHas(env.store, 'bucket') && env.store.bucket != ''
    then env.store.bucket
    else 'tidepool-%s-%s-data' % [config.cluster.name, env.name],

  role(config, name):: config.cluster.name + '-' + name + '-role',

  roleAnnotation(config, name):: {
    'iam.amazonaws.com/role': $.role(config, name),
  },

  permittedAnnotation(config, name):: {
    'iam.amazonaws.com/permitted': "%s-.*" % config.cluster.name 
  },

  iamObject(config, group, iamKind):: {
    local this = self,
    apiVersion:: '2012-10-17',
    kind:: 'AWS::IAM::' + iamKind,
    metadata:: {
      name:: group.name,
    },

    values:: {
      Type: this.kind,
    },
    [self.iamName(config, group, iamKind)]: this.values,
  },

  iamName(config, group, iamKind):: str.capitalize(str.camelCase(group.name) + str.camelCase(iamKind)),

  iamManagedPolicy(config, group):: $.iamObject(config, group, 'ManagedPolicy') {
    local this = self,
    values+:: {
      Properties: {
        PolicyDocument: {
          Version: this.apiVersion,
        },
      },
    },
  },

  iamRole(config, group):: $.iamObject(config, group, 'Role') {
    local this = self,
    values+:: {
      Properties: {
        RoleName: '%s-%s-role' % [config.cluster.name, group.name],
        ManagedPolicyArns: [{
          Ref: $.iamName(config, group, 'ManagedPolicy'),
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
                    $.iamName(config, config.groups.kiam, 'Role'),
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
