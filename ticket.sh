#!/bin/bash

echo "==> Following are the readiness, liveness, and startup probes present in the deployments in the cluster:"
echo ""

# part 1
## get the names of all pods and namespaces into an array 
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
## get the names of all images in an array
#images_array=$(kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n')
images_array=$(kubectl get deployments --all-namespaces -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n')

echo "==> Following are the images deployed in the cluster:"
echo ""

for image in $images_array
do
    echo "$image"
done


# part 3
## install jq
# apt-get update
# apt-get install jq

## method 1:
## pull every images from dockerhub and inspect it for labels

# for image in $images_array
# do
#     echo "$image"
#     docker pull $image
#     docker inspect $image | jq '.[0].ContainerConfig.Labels'
#     docker rmi $image
#     echo ""
# done

## method 2:
## use the built API for fetching image labels

## API not provided