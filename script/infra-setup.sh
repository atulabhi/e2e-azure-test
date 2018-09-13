#!/bin/bash
set -e

#set-up EYE on client

echo "set-up EYE on client"
mkdir ~/.kube packet-openebs packet-openebs/cluster 
cp -r packet/.kube/. ~/.kube/
echo " deploying Aggrigrator and Forwarder on client"
wget https://raw.githubusercontent.com/openebs/e2e-infrastructure/master/production/efk-client/playbook/efk-vars.yml
wget https://raw.githubusercontent.com/openebs/e2e-infrastructure/master/production/efk-client/playbook/efk.yml
wget https://raw.githubusercontent.com/openebs/e2e-infrastructure/master/production/efk-client/playbook/get_url.yml
ansible-playbook efk.yml --extra-vars "commit_id=$CI_COMMIT_SHA pipeline_id=$CI_PIPELINE_ID" 

echo "***************************************"
echo "Pipeline IDS"
echo $CI_PIPELINE_ID
echo $CI_PIPELINE_IID
echo "***************************************"
###########

# Deploy OpenEBS

echo "deploying OpenEBS"

cp -r packet/cluster/. packet-openebs/cluster
wget https://raw.githubusercontent.com/atulabhi/litmus/v0.7-RC1/providers/openebs/installers/operator/master/litmusbook/openebs_setup.yaml
kubectl apply -f openebs_setup.yaml

sleep 120
kubectl get po --all-namespaces


litmus_pod=$(kubectl get pod -a -n litmus --no-headers -o custom-columns=:metadata.name)
status_cmd='kubectl logs $litmus_pod -n litmus -c ansibletest'
while [[ $(kubectl get pod $litmus_pod --no-headers -n litmus -o custom-columns=:status.phase) =~ 'Running' ]]
do
   echo "Still Running sir..."
   sleep 1
done
if [[ ! $(eval $status_cmd) =~ 'FAILED!' ]]; then
   TestStatus='Pass'
else
  TestStatus='Fail'
fi
echo $TestStatus

echo "========================================================================="

eval $status_cmd