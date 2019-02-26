helm install --name flux \
--set rbac.create=true \
--set helmOperator.create=true \
--set git.url=git@github.com:tidepool-org/dev-ops \
--set git-poll-interval=1m \
--namespace flux \
weaveworks/flux
