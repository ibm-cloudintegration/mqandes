#!/bin/bash
set -x
namespace=${1:-"cp4i-mq"}
QMname=$2
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd $SCRIPT_DIR
echo "***********************************"
echo " Update java source code "
echo "***********************************"
pwd
##src/main/java/com/ibm/example
  
cat src/main/java/com/ibm/example/readMQMessages.template | sed -e "s#{{QMInstance}}#$namespace#g;" -e "s#{{NAMESPACE}}#$namespace#g;" -e "s#{{QMName}}#$QMname#g;" > src/main/java/com/ibm/example/readMQMessages.java

echo "Deploying to $namespace"

oc project $namespace
oc new-build --name paymentgateway --binary --strategy docker
oc start-build paymentgateway --from-dir . --follow

cat deployment.yaml_template |
  sed "s#{{NAMESPACE}}#$namespace#g;" > deployment.yaml
  
oc apply -f deployment.yaml -n $namespace
