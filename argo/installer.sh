
# Check/Install required packages
REQUIRED_PKG=("kubectl" "curl")

for PKG in "${REQUIRED_PKG[@]}"
do
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $PKG|grep "install ok installed")
    echo Checking for $PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
    echo "No $PKG. Setting up $PKG."

    read -p "Do you wish to install $PKG (y/n)? " yn
        case $yn in
            [Yy]* ) echo "instala" $PKG; exit;;
            # [Yy]* ) sudo apt-get --yes install $PKG; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes(y/Y) or no(n/N).";;
        esac

    fi
done

# Check connection with kuberentes
kubectl cluster-info 2>&1 > /dev/null

if [ $? -eq 1 ]
then
  echo "Check the kubernetes connection"
  exit 1
fi

# Argocd binary installation
echo -e "\n++ Installing argocd binary:"
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd


# Argo Installation
echo -e "\n++ Installing argocd on kubernetes:"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
PORT_80=$(kubectl get svc argocd-server -n argocd -o jsonpath="{.spec.ports[0].nodePort}")
PORT_443=$(kubectl get svc argocd-server -n argocd -o jsonpath="{.spec.ports[1].nodePort}")
echo "Access Argo using Nodeport $PORT_80 or $PORT_443"

SECRET_NAME="argocd-initial-admin-secret"
read -p "Do you wish to show the argo admin password (y/n)? " yn
case $yn in
    # [Yy]* ) echo "instala argo"; break;;
    [Yy]* ) 
    while [ $? -eq 1 ]
    do
    echo "Waiting for the ${SECRET_NAME} secret"
    sleep 10s
    kubectl -n argocd get ${SECRET_NAME} test 2> /dev/null
    done
    echo "Secret test created"
    PASS=$(kubectl -n argocd get secret ${SECRET_NAME} -o jsonpath="{.data.password}" | base64 -d) ; echo -e "+++ Argocd credentials:\nUser: admin\nPassword: ${PASS}"; exit;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes(y/Y) or no(n/N).";;
esac


