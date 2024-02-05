KUBECONFIG="/Users/minelie.goma-lembet/.kube/config.dev1ms"
STATE_FILE="/Users/minelie.goma-lembet/Downloads/reports/reports.txt"
SNS_TOPIC_ARN="arn:aws:sns:us-west-2:876972130410:budderfly_website" # Replace with your SNS topic ARN

# Check command execution success
check_command_success() {
   if [ $? -ne 0 ]; then
       echo "Command failed: $1"
       exit 1
   fi
}

# Read the state file to get previously OOMKilled pods
read_previous_state() {
   if [ -f "$STATE_FILE" ]; then
       grep -i $1 "$STATE_FILE"
   else
       echo ""
   fi
}

# Save current state to the state file
save_current_state() {
   echo "$1" >> "$STATE_FILE"
}

replace_current_state() {
   sed -i '' "s/$1/$2/" "$STATE_FILE"
}

# Send SNS notification
send_sns_notification() {
   local pod_name=$1
   local reason=$2
   local message="New Terminated event detected for Pod: $pod_name, for the reason: $reason"
   aws sns publish --topic-arn "$SNS_TOPIC_ARN" --message "$message"
}

# Get pods and check for OOMKilled status
check_pods() {
   local current_state=""
   local pods=$(kubectl --kubeconfig="$KUBECONFIG" get pods --all-namespaces -o jsonpath="{range .items[*]}{.metadata.namespace}/{.metadata.name}{'\n'}{end}")
   check_command_success "kubectl --kubeconfig='$KUBECONFIG' get pods"

   for pod_name in $pods; do
       local pod=$(echo $pod_name | cut -f2 -d'/')
       local ns=$(echo $pod_name | cut -f1 -d'/')
       latest_status=$(kubectl --kubeconfig="$KUBECONFIG" describe pod "$pod" -n $ns | grep -i "last state" | awk -F: '{print $2}')
       latest_reason=$(kubectl --kubeconfig="$KUBECONFIG" describe pod "$pod" -n $ns | grep -i "reason" | awk -F: '{print $2}')
       local previous_state=$(read_previous_state $pod)
       last_terminate=$(kubectl --kubeconfig="$KUBECONFIG" describe pod "$pod" -n $ns | grep -i "finished" | awk -F: '{print $2}')

       if [[ $latest_reason =~ "OOMKilled" ]]; then
           echo "$latest_status $latest_reason"
           echo "Pod $pod was terminated for the reason: $latest_reason"
           current_state="$pod $last_terminate"

           if [[ ! $previous_state =~ $current_state ]]; then
               echo "New Terminated event detected for Pod: $pod"
               #save_current_state "$current_state"
               send_sns_notification "$pod" "$latest_reason"

               if [ -z "$previous_state" ]; then
                   save_current_state "$current_state"
               else
                   replace_current_state "$previous_state" "$current_state"
               fi
           fi
       fi
   done
  
}

# Main script execution
check_pods
