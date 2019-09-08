 local updateFlux(deployment) = (
    local container = deployment.spec.template.spec.containers[0];

   deployment 
    + {
    spec+: {
      template+: {
        spec+: {
           containers: [ container {
              args+: ['--sync-interval=1m', '--git-poll-interval=1m', '--connect=ws://fluxcloud']
           } ] }
        },
      },
    }
 );
 
 local updateHelmOperator(deployment) = (
   local container = deployment.spec.template.spec.containers[0];
   deployment + {
     spec+: {
       template+: {
         spec+: {
           volumes+: [
             {
               name: 'repositories-yaml',
               secret: {
                 secretName: 'flux-helm-repositories',
               },
             },
             {
               name: 'repositories-cache',
               emptyDir: {},
             },
           ],
           containers: [
             container {
               volumeMounts+: [
                 {
                   name: 'repositories-yaml',
                   mountPath: '/var/fluxd/helm/repository',
                 },
                 {
                   name: 'repositories-cache',
                   mountPath: '/var/fluxd/helm/repository/cache',
                 },
               ],
             },
           ],
         },
       },
     },
   }
 );

function(flux, helm) {
  flux: updateFlux(flux),
  helm: updateHelmOperator(helm),
}

