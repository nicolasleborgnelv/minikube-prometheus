#!/bin/bash

# https://docs.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad

# Set the `errexit` option to make sure that
# if one command fails, all the script execution
# will also fail (see `man bash` for more 
# information on the options that you can set).
set -o errexit

main () {
    myNamespace=prometheus
    NS=$(kubectl get namespace $myNamespace --ignore-not-found);
    if [[ "$NS" ]]; then
        echo "Skipping creation of namespace $myNamespace - already exists";
    else
        echo "Creating namespace $myNamespace";
        kubectl create namespace $myNamespace;
    fi;
    # deploy prometheus with argocd
    kubectl apply -n argocd -f prometheus.yaml
    # sync the application
    argocd login argocd.minikube:$(kubectl get --namespace=traefik svc traefik-ingress-service -o=jsonpath='{.spec.ports[?(@.port==80)].nodePort}{"\n"}') --grpc-web --insecure  --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    argocd app sync prometheus
    # show access path
    echo "http://prometheus.minikube:$(kubectl get --namespace=traefik svc traefik-ingress-service -o=jsonpath='{.spec.ports[?(@.port==80)].nodePort}{"\n"}')"
    echo "http://grafana.minikube:$(kubectl get --namespace=traefik svc traefik-ingress-service -o=jsonpath='{.spec.ports[?(@.port==80)].nodePort}{"\n"}')"

}
main "$@"
