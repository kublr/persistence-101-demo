#!/bin/sh

# Authenticate with Kublr Control Plane

eval "$(curl -s \
  -d "grant_type=password" \
  -d "scope=openid" \
  -d "client_id=kublr-ui" \
  -d "username=${KCP_USERNAME}" \
  -d "password=${KCP_PASSWORD}" \
  "${KCP_URL}/auth/realms/kublr-ui/protocol/openid-connect/token" | \
  jq -r '"REFRESH_TOKEN="+.refresh_token,"TOKEN="+.access_token,"ID_TOKEN="+.id_token')"

# Download Kubernetes kubeconfig file

function getConfig() {
  if ! curl -ksSf -XGET -H "Authorization: Bearer ${TOKEN}" \
    "${KCP_URL}/api/spaces/${KCP_SPACE}/cluster/${KCP_CLUSTER}/admin-config" > \
    "tmp-config-${KCP_CLUSTER}.yaml" ; then
    return 1
  fi

  mv -f "tmp-config-${KCP_CLUSTER}.yaml" "config-${KCP_CLUSTER}.yaml"

  export KUBECONFIG="$(pwd)/config-${KCP_CLUSTER}.yaml"

  echo "KUBECONFIG at config-${KCP_CLUSTER}.yaml"
  if [ -n "${1}" ] ; then
    alias ${1}="kubectl --kubeconfig='$(pwd)/config-${KCP_CLUSTER}.yaml'"
    echo "kubectl alias set to '${1}'"
  fi
}

KCP_SPACE=transient

KCP_CLUSTER=persistence-101-aws

getConfig kaws

KCP_CLUSTER=persistence-101-azure

getConfig kaz

