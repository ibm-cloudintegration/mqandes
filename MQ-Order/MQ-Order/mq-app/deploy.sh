#!/bin/bash

namespace=${1:-"cp4i-mq"}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd $SCRIPT_DIR
echo "***********************************"
echo " Update java source code "
echo "***********************************"

##src/main/java/com/ibm/example
cat src/main/java/com/ibm/example/readMQMessages.template |
  sed "s#{{NAMESPACE}}#$namespace#g;" > src/main/java/com/ibm/example/readMQMessages.java

echo "Deploying to $namespace"

oc project $namespace
oc new-build --name paymentgateway --binary --strategy docker
oc start-build paymentgateway --from-dir . --follow

cat deployment.yaml_template |
  sed "s#{{NAMESPACE}}#$namespace#g;" > deployment.yaml
  
oc apply -f deployment.yaml -n $namespace
