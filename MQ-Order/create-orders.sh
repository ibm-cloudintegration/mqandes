#!/bin/bash
#
# This is the spinner to show when things are being installed.  
#
spinner() {
  local i=0
  local spinner=("-" "\\" "|" "/")
  while :; do
    printf "${red}\b${spinner[i++]}"
    sleep 0.1
    ((i=i%4))
  done
}
if [ $# -eq 0 ]
  then
 echo " Missing your Namespace"
 exit
fi 
#
# Save the NameSpace passed in and create the QMgr name. 
# If this is demo for cp4i-mq NS set the QMgr name.
#
if [ $# -eq 1 ]
  then
 export NAMESPACE=$1
  if [ $NAMESPACE == "cp4i-mq" ]
   then
    export QMName="ordersnew01"
    export QMInstance=$QMName
    else 
    number=$(echo "$NAMESPACE" | grep -o '[0-9.]*')
    export QMName="ordersnew$number"
    export QMInstance=$NAMESPACE"-"$QMName
  fi
 else 
 echo " To many arguments passed in"
 exit
fi
#
# Setup variables 
#
source mq.properties
textreset=$(tput sgr0) # reset the foreground colour
red=$(tput setaf 1)
green=$(tput setaf 2) 
yellow=$(tput setaf 3) 
bold=$(tput bold)
normal=$(tput sgr0)
#
# make sure you are logged onto the correct OpenShift Cluster
#
oc cluster-info > /dev/null 2>&1
if [ $? -eq 0 ];
  then
    OCP_CLUSTER=$(oc project | cut -d ' ' -f 6)
     echo "${bold}Your current Cluster:${textreset}"
     echo "$OCP_CLUSTER"
  else 
   {	
    echo "${red}[ERROR]${textreset}You are NOT login to a OCP cluster"
    echo "Login to your OCP cluster and rerun the script"
    exit 1
   }
 fi
#
# Check if this is the OCP cluster you are setting up
#	 
 while true; do
   read -p "${bold}Is this the cluster you are setting up? (Y/N)${textreset}" yn
   case $yn in
       [Yy]* ) break;;
       [Nn]* ) exit 1;;
       * ) echo "Please answer y or n.";;
   esac
 done
#
echo "-------------------------------------------"
echo "   Create your new order QMgr  "
echo "-------------------------------------------"
#
cat orders-new.template_yaml |
  sed -e "s#{{NAMESPACE}}#$NAMESPACE#g" -e "s#{{MQ_LICENSE}}#$MQ_LICENSE#g" -e "s#{{QMInstance}}#$QMInstance#g" -e "s#{{MQ_VERSION}}#$MQ_VERSION#g" -e "s#{{QMName}}#$QMName#g" > orders-new.yaml
oc apply -f orders-new.yaml  -n $NAMESPACE > /dev/null 2>&1
printf "[INFO] Install the ${bold}MQ instance ${normal}"
#
# Run the spinner in the background
      spinner &
      spinner_pid=$!          
#             
    while true;
        do
           STATUS=`oc get QueueManager -n $NAMESPACE | grep ordersnew 2>&1`
           echo $STATUS | grep Running > /dev/null 2>&1
        if [ $? = 0 ]
         then
          echo ""
          echo "${green}[INFO]${textreset} MQ is ready"
          break;
          else        
            sleep 5
        fi
        done
        # Kill the spinner process
         kill $spinner_pid
 #
echo "-------------------------------------------"
echo "   Create your payment app and deploy      "
echo "-------------------------------------------"
oc get deploy paymentgateway -n $NAMESPACE | grep 1/1 > /dev/null 2>&1
if [ $? = 0 ]
   then 
     echo "${green}[INFO]${textreset}  ${bold}Payment App${normal} already installed"
     else
     {
     printf " This will take a little time ..." 
#
# Run the spinner in the background
#
      spinner &
      spinner_pid=$!  
cd mq-app
./deploy.sh $NAMESPACE $QMInstance $QMName > /dev/null 2>&1
echo "${textreset}"
# Kill the spinner process
  kill $spinner_pid
  cd ..
  }
  fi
  
echo "-------------------------------------------"
echo "   Create your new order sink connector  "
echo "-------------------------------------------"
#
cat mq-sink.template_yaml |
  sed -e "s#{{NAMESPACE}}#$NAMESPACE#g;" -e "s#{{QMName}}#$QMName#g" -e "s#{{QMInstance}}#$QMInstance#g" > mq-sink.yaml
          
oc apply -f mq-sink.yaml  -n cp4i-eventstreams
##rm mq-sink.yaml

echo "-------------------------------------------"
echo "   Create your new order source connector  "
echo "-------------------------------------------"
#
if [ $NAMESPACE == "cp4i-mq" ]
   then
    TOPIC="MYDEMO.ORDER.PAYMENT"
    else 
    TOPIC="${NAMESPACE^^}.ORDER.PAYMENT"
  fi
echo "Your topic name will be - $TOPIC"
cat mq-source.template_yaml |
  sed -e "s#{{NAMESPACE}}#$NAMESPACE#g" -e "s#{{TOPIC}}#$TOPIC#g"  -e "s#{{QMName}}#$QMName#g" -e "s#{{QMInstance}}#$QMInstance#g" > mq-source.yaml

oc apply -f mq-source.yaml  -n cp4i-eventstreams
##rm mq-sink.yaml 
