#!/bin/bash -ix
#
# Configure EKS cluster to run Tidepool services
#

set -o pipefail

function cluster_in_context {
        context=$(KUBECONFIG=$(get_kubeconfig) kubectl config current-context 2>/dev/null)
        if [ $? -eq 0 ]
        then
                echo $context
        else
                echo "none"
        fi
}

function make_envrc {
        local context=$(get_context)
        context=$(yq r kubeconfig.yaml current-context)
        echo "kubectx $context" >.envrc
        add_file ".envrc"
}

function cluster_in_repo {
        yq r kubeconfig.yaml -j current-context | sed -e 's/"//g' -e "s/'//g"
}

function get_sumo_accessID {
	echo $1 | jq '.accessID' | sed -e 's/"//g'
}

function get_sumo_accessKey {
	echo $1 | jq '.accessKey' | sed -e 's/"//g'
}

function install_sumo {
        start "installing sumo" 
        local config=$(get_config)
	local cluster=$(get_cluster)
	local namespace=$(require_value "pkgs.sumologic.namespace")
	local apiEndpoint=$(require_value "pkgs.sumologic.apiEndpoint")
        local sumoSecret=$(aws secretsmanager get-secret-value  --secret-id $cluster/$namespace/sumologic | jq '.SecretString | fromjson')
	local accessID=$(get_sumo_accessID $sumoSecret)
	local accessKey=$(get_sumo_accessKey $sumoSecret)
	curl -s https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/master/deploy/docker/setup/setup.sh \
		| bash -s - -k $cluster -n $namespace -d false $apiEndpoint $accessID $accessKey > pkgs/sumologic/sumologic.yaml
	complete "installed sumo"
}


function add_gloo_manifest {
        config=$1
        file=$2
        (cd gloo; \
        jsonnet --tla-code config="$config" $TEMPLATE_DIR/gloo/${file}.yaml.jsonnet | separate_files | add_names; \
        expect_success "Templating failure gloo/$1.yaml.jsonnet")
}

# install gloo
function install_gloo {
        start "installing gloo" 
        local config=$(get_config)
        jsonnet --tla-code config="$config" $TEMPLATE_DIR/gloo/gloo-values.yaml.jsonnet | yq r - > $TMP_DIR/gloo-values.yaml
        expect_success "Templating failure gloo/gloo-values.yaml.jsonnet"

        rm -rf gloo
        mkdir -p gloo
        (cd gloo; glooctl install gateway -n gloo-system --values $TMP_DIR/gloo-values.yaml --dry-run | separate_files | add_names)
        expect_success "Templating failure gloo/gloo-values.yaml.jsonnet"
        add_gloo_manifest "$config" gateway-ssl
        add_gloo_manifest "$config" gateway
        add_gloo_manifest "$config" settings

        glooctl install gateway -n gloo-system --values $TMP_DIR/gloo-values.yaml
        expect_success "Gloo installation failure"
        completed "installed gloo"
}

function confirm_matching_cluster {
        local in_context=$(cluster_in_context)
        local in_repo=$(cluster_in_repo)
        if  [ "${in_repo}" != "${in_context}" ]
        then
                echo "${in_context} is cluster selected in KUBECONFIG config file"
                echo "${in_repo} is cluster named in $REMOTE_REPO repo"
                confirm "Is $REMOTE_REPO the repo you want to use? "
        fi
}

function establish_ssh {
        ssh-add -l &>/dev/null
        if [ "$?" == 2 ]; then
                # Could not open a connection to your authentication agent.

                # Load stored agent connection info.
                test -r ~/.ssh-agent && \
                eval "$(<~/.ssh-agent)" >/dev/null

                ssh-add -l &>/dev/null
                if [ "$?" == 2 ]; then
                        # Start agent and store agent connection info.
                        (umask 066; ssh-agent > ~/.ssh-agent)
                        eval "$(<~/.ssh-agent)" >/dev/null
                fi
        fi

        # Load identities
        ssh-add -l &>/dev/null
        if [ "$?" == 1 ]; then
                # The agent has no identities.
                # Time to add one.
                ssh-add -t 4h
        fi
}

# set up colors to use for output
function define_colors {
        RED=`tput setaf 1`
        GREEN=`tput setaf 2`
        MAGENTA=`tput setaf 5`
        RESET=`tput sgr0`
}

# irrecoverable error. Show message and exit.
function panic {
        echo "${RED}[✖] ${1}${RESET}"
        exit 1
}

# confirm that previous command succeeded, otherwise panic with message
function expect_success {
        if [ $? -ne 0 ]
        then
                panic "$1"
        fi
}

# show info message
function start {
        echo "${GREEN}[i] ${1}${RESET}"
}

# show info message
function complete {
        echo "${MAGENTA}[√] ${1}${RESET}"
}

# show info message
function info {
        echo "${MAGENTA}[√] ${1}${RESET}"
}

# report that file is being added to config repo
function add_file {
        echo "${GREEN}[ℹ] adding ${1}${RESET}"
}

# report all files added to config repo from list given in stdin
function add_names {
        while read -r line
        do
                add_file $line
        done
}

# report renaming of file in config repo
function rename_file {
        echo "${GREEN}[√] renaming ${1} ${2}${RESET}"
}

# conform action, else exit
function confirm {
        if [ "$APPROVE" != "true" ]
        then
                local msg=$1
                read -p "${RED}$msg${RESET} " -n 1 -r
                if [[ ! $REPLY =~ ^[Yy]$ ]]
                then
                        exit 1
                else
                        echo
                fi
        fi
}

# require that REMOTE_REPO env variable exists, expand REMOTE_REPO into full name
function check_remote_repo {

        if [ -z "$REMOTE_REPO" ]
        then
                panic "must provide REMOTE_REPO"
        fi

        if [[ $REMOTE_REPO != */* ]]
        then
                GIT_REMOTE_REPO="git@github.com:tidepool-org/$REMOTE_REPO"
        else
                GIT_REMOTE_REPO=$REMOTE_REPO
        fi
        HTTPS_REMOTE_REPO=$(echo $GIT_REMOTE_REPO | sed -e "s#git@github.com:#https://github.com/#")

}

# clean up all temporary files
function cleanup {
        if [ -f "$TMP_DIR" ]
        then
                cd /
                rm -rf $TMP_DIR
        fi
}


# create temporary workspace to clone Git repos into, change to that directory
function setup_tmpdir {
        if [[ ! -d $TMP_DIR ]]; then
                start "creating temporary working directory"
                TMP_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'TMP_DIR'`
                complete "created temporary working directory"
                trap cleanup EXIT
                cd $TMP_DIR
        fi
}

function repo_with_token {
        local repo=$1
        echo $repo | sed -e "s#https://#https://$GITHUB_TOKEN@#"
}


# clone config repo, change to that directory
function clone_remote {
        cd $TMP_DIR
        if [[ ! -d $(basename $HTTPS_REMOTE_REPO) ]]; then
                start "cloning remote"
                git clone $(repo_with_token $HTTPS_REMOTE_REPO)
                expect_success "Cannot clone $HTTPS_REMOTE_REPO"
                complete "cloned remote"
        fi
        cd $(basename $HTTPS_REMOTE_REPO)
}

# clone quickstart repo, export TEMPLATE_DIR
function set_template_dir {
        if [[ ! -d $TEMPLATE_DIR ]]; then
                start "cloning quickstart"
                pushd $TMP_DIR >/dev/null 2>&1
                git clone $(repo_with_token https://github.com/tidepool-org/eks-template)
                export TEMPLATE_DIR=$(pwd)/eks-template
                popd >/dev/null 2>&1
                complete "cloned quickstart"
        fi
}

# clone development repo, exports DEV_DIR and CHART_DIR
function set_tools_dir {
        if [[ ! -d $CHART_DIR ]]; then
                start "cloning development tools"
                pushd $TMP_DIR >/dev/null 2>&1
                git clone $(repo_with_token https://github.com/tidepool-org/development)
                cd development
                git checkout develop
                DEV_DIR=$(pwd)
                CHART_DIR=${DEV_DIR}/charts/tidepool/0.1.7
                popd >/dev/null 2>&1
                complete "cloned development tools"
        fi
}

# clone secret-map repo, export SM_DIR
function clone_secret_map {
        if [[ ! -d $SM_DIR ]]; then
                start "cloning secret-map"
                pushd $TMP_DIR >/dev/null 2>&1
                git clone $(repo_with_token https://github.com/tidepool-org/secret-map)
                SM_DIR=$(pwd)/secret-map
                popd >/dev/null 2>&1
                complete "cloned secret-map"
        fi
}

# get values file
function get_config {
        yq r values.yaml -j
}

# retrieve value from values file, or exit if it is not available
function require_value {
        local val=$(yq r values.yaml -j $1 | sed -e 's/"//g' -e "s/'//g")
        if [ $? -ne 0 -o "$val" == "null" -o "$val" == "" ]
        then
                panic "Missing $1 from values.yaml file."
        fi
        echo $val
}

# retrieve name of cluster
function get_cluster {
        require_value "cluster.metadata.name"
}

# retrieve name of region
function get_region {
        require_value "cluster.metadata.region"
}

# retrieve email address of cluster admin
function get_email {
        require_value "email"
}

# retrieve AWS account number
function get_aws_account {
        require_value "aws.accountNumber"
}

# retrieve list of AWS environments to create
function get_environments {
        yq r values.yaml environments | sed -e "/^  .*/d" -e s/:.*//
}

# retrieve list of K8s system masters
function get_iam_users {
        yq r values.yaml aws.iamUsers | sed -e "s/- //" -e 's/"//g'
}

# retrieve bucket name or create from convention
function get_bucket {
        local env=$1
        local kind=$2
        local bucket=$(yq r values.yaml environments.${env}.tidepool.buckets.${kind} | sed -e "/^  .*/d" -e s/:.*//)
        if [ "$bucket" == "null" ]
        then
                local cluster=$(get_cluster)
                echo "tidepool-${cluster}-${env}-${kind}"
        else
                echo $bucket
        fi
}

# create Tidepool assets bucket
function make_assets {
        local env
        for env in $(get_environments)
        do
                local bucket=$(get_bucket $env asset)
                  start "creating asset bucket $bucket"
                  aws s3 mb s3://$bucket
                  info "copying  dev assets into $bucket"
                  aws s3 cp s3://tidepool-dev-asset s3://$bucket
                  complete "created asset bucket $bucket"
        done
}

# retrieve helm home
function get_helm_home {
        echo ${HELM_HOME:-~/.helm}
}

# make TLS certificate to allow local helm client to access tiller with TLS
function make_cert {
        local cluster=$(get_cluster)
        local helm_home=$(get_helm_home)

        start "installing helm client cert for cluster $cluster"

        info "retrieving ca.pem from AWS secrets manager"
        aws secretsmanager get-secret-value --secret-id $cluster/flux/ca.pem | jq '.SecretString' | sed -e 's/"//g' \
-e 's/\\n/\
/g' >$TMP_DIR/ca.pem

        expect_success "failed to retrieve ca.pem from AWS secrets manager"

        info "retrieving ca-key.pem from AWS secrets manager"
        aws secretsmanager get-secret-value --secret-id $cluster/flux/ca-key.pem | jq '.SecretString' | sed -e 's/"//g'  \
-e 's/\\n/\
/g' >$TMP_DIR/ca-key.pem

        expect_success  "failed to retrieve ca-key.pem from AWS secrets manager"

        local helm_cluster_home=${helm_home}/clusters/$cluster

        info "creating cert in ${helm_cluster_home}"
        local tiller_hostname=tiller-deploy.flux
        local user_name=helm-client

        echo '{"signing":{"default":{"expiry":"43800h","usages":["signing","key encipherment","server auth","client auth"]}}}' > $TMP_DIR/ca-config.json
        echo '{"CN":"'$user_name'","hosts":[""],"key":{"algo":"rsa","size":4096}}' | cfssl gencert \
          -config=$TMP_DIR/ca-config.json -ca=$TMP_DIR/ca.pem -ca-key=$TMP_DIR/ca-key.pem \
          -hostname="$tiller_hostname" - | cfssljson -bare $user_name

        rm -rf $helm_cluster_home
        mkdir -p $helm_cluster_home
        mv helm-client.pem $helm_cluster_home/cert.pem
        add_file $helm_cluster_home/cert.pem
        mv helm-client-key.pem $helm_cluster_home/key.pem
        rm helm-client.csr
        add_file $helm_cluster_home/key.pem
        cp $TMP_DIR/ca.pem $helm_cluster_home/ca.pem
        add_file $helm_cluster_home/ca.pem
        rm -f $helm_home/{cert.pem,key.pem,ca.pem}
        cp $helm_cluster_home/{cert.pem,key.pem,ca.pem} $helm_home

        if [ "$TILLER_NAMESPACE" != "flux"  -o "$HELM_TLS_ENABLE" != "true" ]
        then
                    info "you must do this to use helm:"
                    info "export TILLER_NAMESPACE=flux"
                    info "export HELM_TLS_ENABLE=true"
        fi
        complete "installed helm client cert for cluster $cluster"
}

# config availability of GITHUB TOKEN in environment
function expect_github_token {
        if [ -z "$GITHUB_TOKEN" ]
        then
                panic "\$GITHUB_TOKEN required. https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line"
        fi
}

# retrieve kubeconfig value
function get_kubeconfig {
        local kc=$(require_value "kubeconfig")
        realpath $(eval "echo $kc")
}

# create EKS cluster using config.yaml file, add kubeconfig to config repo
function make_cluster {
        local cluster=$(get_cluster)
        start "creating cluster $cluster"
        eksctl create cluster -f config.yaml --kubeconfig ./kubeconfig.yaml
        expect_success "eksctl create cluster failed."
        git pull
        add_file "./kubeconfig.yaml"
        make_envrc
        complete "created cluster $cluster"
}

function merge_kubeconfig {
        local local_kube_config=$(realpath ./kubeconfig.yaml)
        local kubeconfig=$(get_kubeconfig)
        if [ "$kubeconfig" != "$local_kube_config" ]
        then
                    if [ -f "$kubeconfig" ]
                    then
                        info "merging kubeconfig into $kubeconfig"
                        KUBECONFIG=$kubeconfig:$local_kube_config kubectl config view --flatten >$TMP_DIR/updated.yaml
                        cat $TMP_DIR/updated.yaml > $kubeconfig
                    else
                        mkdir -p $(dirname $kubeconfig)
                        info "creating new $kubeconfig"
                        cat $local_kube_config > $kubeconfig
                    fi
        fi
}

# confirm that values file exists or panic
function expect_values_exists {
        if [ ! -f values.yaml ]
        then
                panic "No values.yaml file."
        fi
}

# remove computed pkgs
function reset_config_dir {
        mv values.yaml $TMP_DIR/
        if [ $(ls | wc -l) -ne 0 ]
        then
                confirm "Are you sure that you want to remove prior contents (except values.yaml)?"
                info "resetting config repo"
                rm -rf pkgs
        fi
        mv $TMP_DIR/values.yaml .
}

# return list of enabled packages
function enabled_pkgs {
        local pkgs=""
        local directory=$1
        local key=$2
        for dir in $(ls $directory)
        do
                local pkg=$(basename $dir)
                local enabled=$(yq r values.yaml $key.${pkg}.enabled)
                if [ "$enabled" == "true" ]
                then
                        pkgs="${pkgs} $pkg"
                fi
        done
        echo $pkgs
}

# make K8s manifest file for shared services given config, path to directory, and prefix to strip
function template_files {
        local config=$1
        local path=$2
        local prefix=$3
        local fullpath
        local cluster=$(get_cluster)
        local region=$(get_region)
        for fullpath in $(find $path -type f -print)
        do
                local filename=${fullpath#$prefix}
                mkdir -p $(dirname $filename)
                if [ "${filename: -5}" == ".yaml" ]
                then
                        add_file $filename
                        cp $fullpath $filename
                elif [ "${filename: -8}" == ".jsonnet" ]
                then
                        add_file ${filename%.jsonnet}
                        jsonnet --tla-code config="$config" $fullpath | yq r - > ${filename%.jsonnet}
                        expect_success "Templating failure $filename"
                fi
        done
}

# make K8s manifest files for shared services
function make_shared_config {
        start "creating package manifests"
        local config=$(get_config)
        rm -rf pkgs
        local dir
        for dir in $(enabled_pkgs $TEMPLATE_DIR/pkgs pkgs)
        do
                template_files "$config" $TEMPLATE_DIR/pkgs/$dir $TEMPLATE_DIR/
        done
        complete "created package manifests"
}

# make EKSCTL manifest file
function make_cluster_config {
        local config=$(get_config)
        start "creating eksctl manifest"
        add_file "config.yaml"
        jsonnet --tla-code config="$config" ${TEMPLATE_DIR}/eksctl/cluster_config.jsonnet | yq r - > config.yaml
        expect_success "Templating failure eksctl/cluster_config.jsonnet"
        complete "created eksctl manifest"
}

# make K8s manifests for enviroments given config, path, prefix, and environment name
function environment_template_files {
        local config=$1
        local path=$2
        local prefix=$3
        local env=$4
        for fullpath in $(find $path -type f -print)
        do
                local filename=${fullpath#$prefix}
                local dir=environments/$env/$(dirname $filename)
                local file=$(basename $filename)
                mkdir -p $dir
                if [ "${file: -8}" == ".jsonnet" ]
                then
			local out=$dir/${file%.jsonnet}
			local prev=$TMP_DIR/$dir/${file%.jsonnet}
                        add_file $out
			if [ -f  $prev ]
			then
				yq r $prev -j > $TMP_DIR/${file%.jsonnet}
			else
				echo "{}" > $TMP_DIR/${file%.jsonnet}
			fi
                        jsonnet  --tla-code-file prev=$TMP_DIR/${file%.jsonnet}  --tla-code config="$config" --tla-str namespace=$env $fullpath | yq r - > $dir/${file%.jsonnet}
                        expect_success "Templating failure $filename"
			rm $TMP_DIR/${file%.jsonnet}
                fi
        done
}

# make K8s manifests for environments
function make_environment_config {
        local config=$(get_config)
        local env
        mv environments $TMP_DIR
        for env in $(get_environments)
        do
                start "creating $env environment manifests"
                for dir in $(enabled_pkgs $TEMPLATE_DIR/environments environments.$env)
                do
                        environment_template_files "$config" $TEMPLATE_DIR/environments/$dir $TEMPLATE_DIR/environments/ $env
                done
                complete "created $env environment manifests"
        done
}

# create all K8s manifests and EKSCTL manifest
function make_config {
        start "creating manifests"
        make_shared_config
        make_cluster_config
        make_environment_config
        complete "created manifests"
}

# persist changes to config repo in GitHub
function save_changes {
        establish_ssh
        start "saving changes to config repo"
        git add .
        complete "added changes to config repo"
        git commit -m "$1"
        complete "committed changes to config repo"
        git push
        complete "pushed changes to config repo"
}

# confirm cluster exists or exist
function expect_cluster_exists {
        local cluster=$(get_cluster)
        eksctl get cluster --name $cluster
        expect_success "cluster $cluster does not exist."
}

# install flux into cluster
function make_flux {
        local cluster=$(get_cluster)
        local email=$(get_email)
        start "installing flux into cluster $cluster"
        establish_ssh
        rm -rf flux
        EKSCTL_EXPERIMENTAL=true unbuffer eksctl install \
                flux -f config.yaml --git-url=${GIT_REMOTE_REPO}.git --git-email=$email --git-label=$cluster  | tee  $TMP_DIR/eksctl.out
        expect_success "eksctl install flux failed."
        git pull
        complete  "installed flux into cluster $cluster"
}

# save Certificate Authority key and pem into AWS secrets manager
function save_ca {
        start "saving certificate authority TLS pem and key to AWS secrets manager"
        local cluster=$(get_cluster)
        local dir=$(cat $TMP_DIR/eksctl.out | grep "Public key infrastructure" | sed -e 's/^.*"\(.*\)".*$/\1/')

        aws secretsmanager describe-secret --secret-id $cluster/flux/ca.pem 2>/dev/null
        if [ $? -ne 0 ]
        then
                    aws secretsmanager create-secret --name $cluster/flux/ca.pem --secret-string "$(cat $dir/ca.pem)"
                    expect_success "failed to create ca.pem to AWS"
                    aws secretsmanager create-secret --name $cluster/flux/ca-key.pem --secret-string "$(cat $dir/ca-key.pem)"
                    expect_success "failed to create ca-key.pem to AWS"
        else
                    aws secretsmanager update-secret --secret-id $cluster/flux/ca.pem --secret-string "$(cat $dir/ca.pem)"
                expect_success "failed to update ca.pem to AWS"
                    aws secretsmanager update-secret --secret-id $cluster/flux/ca-key.pem --secret-string "$(cat $dir/ca-key.pem)"
                expect_success "failed to update ca-key.pem to AWS"
        fi
        complete "saved certificate authority TLS pem and key to AWS secrets manager"
}

# save deploy key to config repo
function make_key {
        start "authorizing access to ${GIT_REMOTE_REPO}"

        local key=$(fluxctl --k8s-fwd-ns=flux identity)
        local reponame="$(echo $GIT_REMOTE_REPO | cut -d: -f2 | sed -e 's/\.git//')"
        local cluster=$(get_cluster)

        curl -X POST -i\
                -H"Authorization: token $GITHUB_TOKEN"\
                --data @- https://api.github.com/repos/$reponame/keys << EOF
        {

                "title" : "flux key for $cluster created by make_flux",
                "key" : "$key",
                "read_only" : false
        }
EOF
        complete  "authorized access to ${GIT_REMOTE_REPO}"
}

# update flux and helm operator manifests
function update_flux {
        start "updating flux and flux-helm-operator manifests"
	local config=$(get_config)

        if [ -f flux/flux-deployment.yaml ]
        then
                yq r flux/flux-deployment.yaml -j > $TMP_DIR/flux.json
                yq r flux/helm-operator-deployment.yaml -j > $TMP_DIR/helm.json
                yq r flux/tiller-dep.yaml -j > $TMP_DIR/tiller.json

                jsonnet --tla-code config="$config" --tla-code-file flux="$TMP_DIR/flux.json"  --tla-code-file helm="$TMP_DIR/helm.json" $TEMPLATE_DIR/flux/flux.jsonnet >$TMP_DIR/updated.json --tla-code-file tiller="$TMP_DIR/tiller.json"
                expect_success "Templating failure flux/flux.jsonnet"

                add_file flux/flux-deployment-updated.yaml
                yq r $TMP_DIR/updated.json flux >flux/flux-deployment-updated.yaml
                expect_success "Serialization flux/flux-deployment-updated.yaml"

                add_file flux/helm-operator-deployment-updated.yaml
                yq r $TMP_DIR/updated.json helm >flux/helm-operator-deployment-updated.yaml
                expect_success "Serialization flux/helm-operator-deployment-updated.yaml"

                add_file flux/tiller-dep-updated.yaml
                yq r $TMP_DIR/updated.json tiller >flux/tiller-dep-updated.yaml
                expect_success "Serialization flux/tiller-dep--updated.yaml"

                rename_file flux/flux-deployment.yaml flux/flux-deployment.yaml.orig
                mv flux/flux-deployment.yaml flux/flux-deployment.yaml.orig

                rename_file flux/helm-operator-deployment.yaml flux/helm-operator-deployment.yaml.orig
                mv flux/helm-operator-deployment.yaml flux/helm-operator-deployment.yaml.orig

                rename_file flux/tiller-dep.yaml flux/tiller-dep.yaml.orig
                mv flux/tiller-dep.yaml flux/tiller-dep.yaml.orig
        fi
        complete "updated flux and flux-helm-operator manifests"
}

function mykubectl {
        KUBECONFIG=~/.kube/config kubectl $@
}

# create service mesh
function make_mesh {
        linkerd check --pre
        expect_success "Failed linkerd pre-check."
        start "installing mesh"
        info "linkerd check --pre"

        rm -rf linkerd
        mkdir -p linkerd
        add_file "linkerd/linkerd-config.yaml"
        (cd linkerd; linkerd install config | separate_files | add_names)
        linkerd install config | mykubectl apply -f -

        linkerd check config
        while [ $? -ne 0 ]
        do
                    sleep 3
                    info  "retrying linkerd check config"
                    linkerd check config
        done
        info "linkerd check config"

        add_file "linkerd/linkerd-control-plane.yaml"
        (cd linkerd; linkerd install control-plane | separate_files | add_names)
        linkerd install control-plane | mykubectl apply -f -

        linkerd check
        while [ $? -ne 0 ]
        do
                    sleep 3
                    info "retrying linkerd check"
                    linkerd check
        done
        complete "installed mesh"
}

# get secrets from legacy environments if requested
function get_secrets {
        local cluster=$(get_cluster)
        local env
        for env in $(get_environments)
        do
                local source=$(yq r values.yaml environments.${env}.tidepool.source)
                if [ "$source" == "null" -o  "$source" == "" ]
                then
                        continue
                fi
                if [ "$source" == "dev" -o "$source" == "stg" -o "$source" == "int" -o "$source" == "prd" ]
                then
                        $SM_DIR/bin/git_to_map $source | $SM_DIR/bin/map_to_k8s $env
                else
                        panic "Unknown secret source $source"
                fi
        done
}

# create k8s system master users
function make_users {
        local group=system:masters
        local cluster=$(get_cluster)
        local aws_region=$(get_region)
        local account=$(get_aws_account)

        start "adding system masters"
        local user
        for user in $(get_iam_users)
        do
                    local arn=arn:aws:iam::${account}:user/${user}
                    eksctl create iamidentitymapping --region=$aws_region  --role=$arn --group=$group --name=$cluster --username=$user
                    while [ $? -ne 0 ]
                    do
                            sleep 3
                                eksctl create iamidentitymapping --region=$aws_region  --role=$arn --group=$group --name=$cluster --username=$user
                        info "retrying eksctl create iamidentitymapping"
                    done
                    info "added $user to cluster $cluster"
        done
        complete "added system masters"
}


# confirm that values.yaml file exists
function expect_values_not_exist {
        if [ -f values.yaml ]
        then
                confirm "Are you sure that you want to overwrite prior contents of values.yaml?"
        fi
}

# create initial values file
function make_values {
        start "creating values.yaml"
        add_file "values.yaml"
        cat $TMP_DIR/eks-template/values.yaml >values.yaml
        cat >>values.yaml <<!
github:
  git: $GIT_REMOTE_REPO
  https: $HTTPS_REMOTE_REPO

!

        yq r values.yaml -j | jq '.cluster.metadata.name = .github.git' | \
        jq '.cluster.metadata.name |= gsub(".*\/"; "")' | \
        jq '.cluster.metadata.name |= gsub("cluster-"; "")' | yq r - > xxx.yaml
        mv xxx.yaml values.yaml
        if [ "$APPROVE" != "true" ]
        then
                ${EDITOR:-vi} values.yaml
        fi
        complete "created values.yaml"
}

# enter into bash to allow manual editing of config repo
function edit_config {
        info "exit shell when done making changes."
        bash
        confirm "Are you sure you want to commit changes?"
}

# show recent diff
function diff_config {
        git diff HEAD~1
}

# edit values file
function edit_values {
        if [ -f values.yaml ]
        then
                info "editing values file for repo $GIT_REMOTE_REPO"
                ${EDITOR:-vi} values.yaml
        else
                panic "values.yaml does not exist."
        fi
}


# generate random secrets
function randomize_secrets {
        local env
        for env in $(get_environments)
        do
                local file
                for file in $(find $CHART_DIR -name \*secret.yaml -print)
                do
                        helm template --namespace $env --set global.secret.generated=true $CHART_DIR  -f  $CHART_DIR/values.yaml -x $file   >$TMP_DIR/x
                        grep "kind" $TMP_DIR/x >/dev/null 2>&1
                        if [ $? -eq 0 ]
                        then
                                cat $TMP_DIR/x
                        fi
                        rm $TMP_DIR/x
                done
        done
}

# delete cluster from EKS, including cloudformation templates
function delete_cluster {
        cluster=$(get_cluster)
        confirm "Are you sure that you want to delete cluster $cluster?"
        start "deleting cluster $cluster"
        eksctl delete cluster --name=$cluster
        expect_success "Cluster deletion failed."
        info "cluster $cluster deletion takes ~10 minutes to complete"
}

# remove service mesh from cluster and config repo
function remove_mesh {
        start "removing linkerd"
        linkerd install --ignore-cluster | mykubectl delete -f -
        rm -rf linkerd
        complete "removed linkerd"
}

function create_repo {
        read -p "${GREEN}repo name?${RESET} "  -r
        REMOTE_REPO=$REPLY
        DATA='{"name":"yolo-test", "private":"true"}'
        D=$(echo $DATA | sed -e "s/yolo-test/$REMOTE_REPO/")

        read -p "${GREEN}Is this for an organization? ${RESET}" -r
        if [[ "$REPLY" =~ (y|Y)* ]]
        then
            read -p $"${GREEN} Name of organization [tidepool-org]?${RESET} " ORG
            ORG=${ORG:-tidepool-org}
            REMOTE_REPO=$ORG/$REMOTE_REPO
            curl https://api.github.com/orgs/$ORG/repos?access_token=${GITHUB_TOKEN} -d "$D"
        else
            read -p $"${GREEN} User name?${RESET} " -r
            REMOTE_REPO=$REPLY/$REMOTE_REPO
            curl https://api.github.com/user/repos?access_token=${GITHUB_TOKEN} -d "$D"
        fi
        complete "private repo created"
        check_remote_repo
}

function gloo_dashboard {
        mykubectl port-forward -n gloo-system  deployment/api-server 8081:8080 &
        open -a "Google Chrome"  http://localhost:8081
}

function remove_gloo {
        glooctl install gateway --dry-run | mykubectl delete -f -
}

# await deletion of a CloudFormation template that represents a cluster before returning
function await_deletion {
        local cluster=$(get_cluster)
        start  "awaiting cluster $cluster deletion"
        aws cloudformation wait stack-delete-complete --stack-name eksctl-${cluster}-cluster
        expect_success "Aborting wait"
        complete "cluster $cluster deleted"
}

# migrate secrets from legacy GitHub repo to AWS secrets manager
function migrate_secrets {
        local cluster=$(get_cluster)
        mkdir -p external-secrets
        (cd external-secrets; get_secrets | external_secret upsert $cluster plaintext | separate_files | add_names)
}

function create_secrets_managed_policy {
        local file=$TMP_DIR/policy.yaml

        local cluster=$(get_cluster)
        local region=$(get_region)
        local stack_name=eksctl-${cluster}-external-secrets-managed-policy
        aws cloudformation describe-stacks --stack-name $stack_name >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
                start "Creating IAM Managed Policy for secrets management for $cluster in region $region"
                local cf_file=file://$(realpath $file)
                local account=$(get_aws_account)
                # XXX - only supports case where cluster == env

                cat >$file <<EOF
                  AWSTemplateFormatVersion: 2010-09-09
                  Description: Kubernetes IAM Role for External Secrets
                  Resources:
                    ExternalSecretsManagedPolicy:
                      Type: AWS::IAM::ManagedPolicy
                      Properties:
                        ManagedPolicyName: $stack_name
                        PolicyDocument:
                          Version: '2012-10-17'
                          Statement:
                          - Effect: Allow
                            Action:
                            - secretsmanager:GetSecretValue
                            Resource:
                            - "arn:aws:secretsmanager:${region}:${account}:secret:${cluster}/*"
                          - Effect: Allow
                            Action:
                            - "ses:*"
                            Resource: "*"
EOF
        	for env in $(get_environments)
        	do
                	local dataBucket=$(get_bucket $env data)
                	local assetBucket=$(get_bucket $env asset)
			cat >>$file <<EOF
                          - Effect: Allow
                            Action:
                            - s3:ListBucket
                            Resource:
                            - "arn:aws:s3:::${dataBucket}/*"
                          - Effect: Allow
                            Action:
                            - s3:GetObject
                            - s3:PutObject
                            - s3:DeleteObject
                            Resource:
                            - "arn:aws:s3:::${dataBucket}/*"
                          - Effect: Allow
                            Action:
                            - s3:ListBucket
                            Resource:
                            - "arn:aws:s3:::${assetBucket}/*"
                          - Effect: Allow
                            Action:
                            - s3:GetObject
                            Resource:
                            - "arn:aws:s3:::${assetBucket}/*"
EOF
		done
                aws cloudformation create-stack --stack-name ${stack_name} --capabilities CAPABILITY_NAMED_IAM --template-body ${cf_file}

                aws cloudformation wait stack-create-complete --stack-name ${stack_name}
                complete "Created IAM Managed Policy for secrets management"
                rm $file
        fi
}

function linkerd_dashboard {
        linkerd dashboard &
}

# show help
function help {
      echo "$0 [-h|--help] (all|values|edit_values|config|edit_repo|cluster|flux|gloo|regenerate_cert|copy_assets|mesh|migrate_secrets|randomize_secrets|upsert_plaintext_secrets|install_users|deploy_key|delete_cluster|await_deletion|remove_mesh|merge_kubeconfig|gloo_dashboard|linkerd_dashboard|managed_policies|diff|envrc)*"
      echo
      echo
      echo "So you want to built a Kubernetes cluster that runs Tidepool. Great!"
      echo "First, create an (empty) configuration repo on GitHub with $0 repo."
      echo "Second, create/edit a configuration file with $0 values."
      echo "Third, gerenate the rest of the configuration with $0 config."
      echo "Fourth, generate the actual AWS EKS cluster with $0 cluster."
      echo "Fifth, install gloo with $0 gloo."
      echo "Sixth, install a service mesh (to encrypt inter-service traffic for HIPPA compliance with $0 mesh"
      echo "Seventh, install the GitOps controller with $0 flux."
      echo "That is it!"
      echo
      echo "----- Basic Commands -----"
      echo "repo    - create config repo on GitHub"
      echo "values  - create initial values.yaml file"
      echo "config  - create K8s and eksctl K8s manifest files"
      echo "cluster - create AWS EKS cluster, add system:master USERS"
      echo "gloo    - install gloo"
      echo "mesh    - install service mesh"
      echo "flux    - install flux GitOps controller, Tiller server, client certs for Helm to access Tiller, and deploy key into GitHub"
      echo "sumo    - install sumologic collector"
      echo
      echo "If you run into trouble or have specific needs, check out these commands:"
      echo
      echo "----- Advanced Commands -----"
      echo "edit_repo - open shell with config repo in current directory.  Exit shell to commit changes."
      echo "regenerate_cert - regenerate client certs for Helm to access Tiller"
      echo "edit_values - open editor to edit values.yaml file"
      echo "copy_assets - copy S3 assets to new bucket"
      echo "migrate_secrets - migrate secrets from legacy GitHub repo to AWS secrets manager"
      echo "randomize_secrets - generate random secrets and persist into AWS secrets manager"
      echo "upsert_plaintext_secrets - read STDIN for plaintext K8s secrets"
      echo "install_users - add system:master USERS to K8s cluster"
      echo "deploy_key - copy deploy key from Flux to GitHub config repo"
      echo "delete_cluster - initiate deletion of the AWS EKS cluster"
      echo "await_deletion - await completion of deletion of gthe AWS EKS cluster"
      echo "merge_kubeconfig - copy the KUBECONFIG into the local $KUBECONFIG file"
      echo "gloo_dashboard - open the Gloo dashboard"
      echo "linkerd_dashboard - open the Linkerd dashboard"
      echo "managed_policies - create managed policies"
      echo "diff - show recent git diff"
      echo "envrc - create .envrc file for direnv to change kubecontexts"
}

if [ $# -eq 0 ]
then
        help
        exit 0
fi

APPROVE=false
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -y|--approve)
      APPROVE=true
      shift 1
      ;;
    -h|--help)
      help
      exit 0
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

unset TMP_DIR
unset TEMPLATE_DIR
unset CHART_DIR
unset DEV_DIR
unset SM_DIR

define_colors

for param in $PARAMS
do
        case $param in
        all)
                check_remote_repo
                expect_github_token
                setup_tmpdir
                clone_remote
                set_template_dir
                set_tools_dir
                expect_values_not_exist
                make_values
                save_changes "Added values"
                make_config
                save_changes "Added config packages"
                create_secrets_managed_policy
                make_cluster
                merge_kubeconfig
                make_users
                save_changes "Added cluster and users"
                install_gloo
                save_changes "Added gloo"
                make_mesh
                save_changes "Added linkerd mesh"
                make_flux
                save_ca
                make_cert
                make_key
                update_flux
                save_changes "Added flux"
                clone_secret_map
                establish_ssh
                migrate_secrets
        establish_ssh
                save_changes "Added migrated secrets"
                ;;
        repo)
                setup_tmpdir
                create_repo
                ;;
        values)
                check_remote_repo
                setup_tmpdir
                clone_remote
                expect_values_not_exist
                set_template_dir
                make_values
                save_changes "Added values"
                ;;
        config)
                check_remote_repo
                setup_tmpdir
                clone_remote
                set_template_dir
                set_tools_dir
                make_config
                save_changes "Added config packages"
                ;;
        cluster)
                check_remote_repo
                setup_tmpdir
                clone_remote
                set_tools_dir
                create_secrets_managed_policy
                make_cluster
                merge_kubeconfig
                make_users
                save_changes "Added cluster and users"
                ;;
        gloo)
                check_remote_repo
                expect_github_token
                setup_tmpdir
                clone_remote
                set_template_dir
                set_tools_dir
                confirm_matching_cluster
                install_gloo
                save_changes "Installed gloo"
                ;;
        flux)
                check_remote_repo
                expect_github_token
                setup_tmpdir
                clone_remote
                set_template_dir
                set_tools_dir
                confirm_matching_cluster
                make_flux
                save_ca
                make_cert
                make_key
                update_flux
                save_changes "Added flux"
                ;;
        mesh)
                check_remote_repo
                setup_tmpdir
                clone_remote
                set_tools_dir
                confirm_matching_cluster
                make_mesh
                save_changes "Added linkerd mesh"
                ;;
        edit_values)
                check_remote_repo
                setup_tmpdir
                clone_remote
                set_template_dir
                set_tools_dir
                edit_values
                make_config
                save_changes "Edited values. Updated config."
                ;;
        regenerate_cert)
                check_remote_repo
                setup_tmpdir
                clone_remote
                set_tools_dir
                make_cert
                ;;
        copy_assets)
                check_remote_repo
                make_assets
                ;;
        randomize_secrets)
                check_remote_repo
                setup_tmpdir
                clone_remote
                set_tools_dir
                local cluster=$(get_cluster)
                mkdir -p external-secrets
                (cd external-secrets; randomize_secrets | external_secret upsert $cluster encoded | separate_files | add_names)
                save_changes "Added random secrets"
                ;;
        migrate_secrets)
                check_remote_repo
                setup_tmpdir
                clone_remote
                set_tools_dir
                clone_secret_map
                establish_ssh
                migrate_secrets
                save_changes "Added migrated secrets"
                ;;
        upsert_plaintext_secrets)
                check_remote_repo
                setup_tmpdir
                clone_remote
                set_tools_dir
                local cluster=$(get_cluster)
                mkdir -p external-secrets
                (cd external-secrets; external_secret upsert $cluster plaintext | separate_files | add_names)
                save_changes "Added plaintext secrets"
                ;;
        install_users)
                check_remote_repo
                setup_tmpdir
                clone_remote
                confirm_matching_cluster
                make_users
                ;;
        deploy_key)
                check_remote_repo
                setup_tmpdir
                clone_remote
                expect_github_token
                make_key
                ;;
        delete_cluster)
                check_remote_repo
                setup_tmpdir
                clone_remote
                confirm_matching_cluster
                delete_cluster
                ;;
        await_deletion)
                check_remote_repo
                setup_tmpdir
                clone_remote
                confirm_matching_cluster
                await_deletion
                info "cluster deleted"
                ;;
        remove_mesh)
                check_remote_repo
                setup_tmpdir
                clone_remote
                confirm_matching_cluster
                remove_mesh
                save_changes "Removed mesh."
                ;;
        edit_repo)
                check_remote_repo
                setup_tmpdir
                clone_remote
                edit_config
                save_changes "Manual changes."
                ;;
        merge_kubeconfig)
                check_remote_repo
                setup_tmpdir
                clone_remote
                merge_kubeconfig
                ;;
        remove_gloo)
                check_remote_repo
                setup_tmpdir
                clone_remote
                confirm_matching_cluster
                remove_gloo
                ;;
        gloo_dashboard)
                check_remote_repo
                setup_tmpdir
                clone_remote
                confirm_matching_cluster
                gloo_dashboard
                ;;
        linkerd_dashboard)
                check_remote_repo
                setup_tmpdir
                clone_remote
                confirm_matching_cluster
                linkerd_dashboard
                ;;
        managed_policies)
                check_remote_repo
                setup_tmpdir
                clone_remote
                create_secrets_managed_policy
                ;;
        diff)
                check_remote_repo
                setup_tmpdir
                clone_remote
                diff_config
                ;;
        envrc)
                check_remote_repo
                setup_tmpdir
                clone_remote
                make_envrc
                save_changes "Added envrc"
                ;;
        sumo)
                check_remote_repo
                setup_tmpdir
                clone_remote
                install_sumo
                ;;
        *)
                panic "unknown command: $param"
                ;;
        esac
done

