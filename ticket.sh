#!/bin/bash

# part 1
echo "==> Following are the readiness, liveness, and startup probes present in the deployments in the cluster:"
echo ""
 
namespace_arr=$(kubectl get deployments --all-namespaces | awk 'NR>1{print $1}')
deployment_arr=$(kubectl get deployments --all-namespaces | awk 'NR>1{print $2}')
readarray deployment_array <<<  $deployment_arr
readarray namespace_array <<< $namespace_arr

## length of the pod array == length of namespace array
len=${!deployment_array[@]}

for i in $len
do 
    echo -ne "Deployment: ${deployment_array[$i]}\r" 
    echo -ne "Namespace: ${namespace_array[$i]}\r" 

    kubectl describe pod -n ${namespace_array[$i]} ${deployment_array[$i]} | grep -i readiness
    kubectl describe pod -n ${namespace_array[$i]} ${deployment_array[$i]} | grep -i liveness
    kubectl describe pod -n ${namespace_array[$i]} ${deployment_array[$i]} | grep -i startup

    echo ""
done

echo ""
echo ""

# part 2
echo "==> Following are the images deployed in the cluster:"
echo ""

images_array=$(kubectl get deployments --all-namespaces -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n')

for image in $images_array
do
    echo "$image"
done

echo ""
echo ""

# part 3
echo "==> Following are the inspection details of images deployed in the cluster:"
echo ""

for image in $images_array
do
    slashcount=$(echo "$image" | tr -cd '/' | wc -c)
    image=$( cut -d '/' -f $slashcount- <<< $image )
    image="$( cut -d '@' -f 1 <<< $image )"

    echo $image

    ref="${1:-$image}"
    repo="${ref%:*}"
    tag="${ref##*:}"
    token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" | jq -r '.token')
    digest=$(curl -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
              -H "Authorization: Bearer $token" \
              -s "https://registry-1.docker.io/v2/${repo}/manifests/${tag}" \
         | jq -r .config.digest)

    code=$(curl -H "Accept: application/vnd.docker.container.image.v1+json" -H "Authorization: Bearer $token" -s -L -s -o /dev/null -I -w "%{http_code}" https://registry-1.docker.io/v2/${repo}/blobs/${digest})

    if ! [ $code = 404 ]; then
        curl -H "Accept: application/vnd.docker.container.image.v1+json" -H "Authorization: Bearer $token" -s -L "https://registry-1.docker.io/v2/${repo}/blobs/${digest}" | jq .
    else
        echo "Image is not present of docker.io registry"
    fi

    echo "********************"
done