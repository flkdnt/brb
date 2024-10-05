#!/bin/bash
#######################################################
# Bash Rclone/Rsync Backup(BRB) - Dante Foulke, 2023
# Scheduler creates backup jobs
#######################################################

#########################
#       Functions 
#########################
function check_schedule () {
  schedule=$( cat $configfile | yq ".jobs[$jci].schedule.modified" )
  option=$( cat $configfile | yq ".jobs[$jci].parameters.command" ) 

  # Check if Scheduling information exists in Config
  if [[ ($schedule == 'null') || ($schedule == '') ]]; then
    echo "New Backup Job found - '$job_name'"
    set_schedule
  else
    listed_timer=$( cat $configfile | yq ".jobs[$jci].schedule.timer" )
    # Check if timer is listed in the configfile
    if [[ ($listed_timer == 'null') || ($listed_timer == '') ]]; then
      echo "Scheduling $job_name"
      set_schedule
    else 
      # Check if Existing timer is active
      active_timer=$( systemctl list-timers --user | grep "$listed_timer" )
      if [[ ($active_timer == 'null') || ($active_timer == '') ]]; then
        echo "Creating new schedule for $job_name"
        set_schedule
      else
        freq_check=$(cat "$systemd_t_timer_path/$listed_timer" | grep "$job_freq" )
        # Check if timer frequency matches parameters in configfile
        # if not, delete and schedule a new timer
        if [[ ($freq_check == 'null') || ($freq_check == '') ]]; then
          systemctl --user stop "$listed_timer"
          echo "Updating schedule frequency for $job_name"
          set_schedule
        else
          timer_svc=$( echo $listed_timer | sed 's/timer/service/')
          svc_check=$(cat "$systemd_t_timer_path/$timer_svc" | grep "$job_cmd" )
          # Check if service execstart matches parameters in configfile
          # if not, delete and schedule a new timer
          if [[ ($svc_check == 'null') || ($svc_check == '') ]]; then
            systemctl --user stop "$listed_timer"
            echo "Updating schedule for $job_name"
            set_schedule
          fi
        fi
      fi
    fi
  fi
}

function error_exit () {
  job_err=$1
  err_param=$2
  RED='\033[1;31m'
  YELLOW='\033[1;33m'
  echo -e "${RED}Error at Job: ${YELLOW}$job_err${RED} - Parameter: ${YELLOW}$err_param"
  exit 1
}

function set_schedule (){
  systemd-run --user --on-calendar "$job_freq" bash -c "$job_cmd"
  timers=($( ls $systemd_t_timer_path | grep "run-" ))
  for timer in "${timers[@]}"; do
    timer_check=$(cat "$systemd_t_timer_path/$timer" | grep "$job_cmd" )
    if [[ ( $timer_check == 'null' ) || ( $timer_check == '' ) ]]; then
      continue
    else
      timer=$( echo $timer | sed 's/service/timer/')
      ttcheck=$( systemctl --user list-timers | grep "$timer" )
      if [[ ( $ttcheck == 'null' ) || ( $ttcheck == '' ) ]]; then
        timer=''
        continue
      else 
        yq -i ".jobs[$jci].schedule.modified = \"$now\"" $configfile
        yq -i ".jobs[$jci].schedule.timer = \"$timer\"" $configfile
        echo "Sucessfully created service for $job_name"
        break
      fi
    fi
  done
  if [[ ( $timer == 'null' ) || ( $timer == '' ) ]]; then
    error_exit $job_name SCHEDULING
  fi
}
function set_job () {
  check_schedule
}
function test_local_path () {
  local_path=$(stat $1 2> /dev/null)
  if [[ ( $local_path == 'null' ) || ( $local_path == '' ) ]]; then
    error_exit "$job_name - Local path '$1' does not exist!" PATH
  else
    return 0
  fi
}
function validate_job () {
  validate_name
  validate_path
  # Validate Frequency with timekeeper.sh
  source "${config_folder}/timekeeper.sh"
  validate_command
}

function validate_command () {
  cmd_args=$(cat $configfile | yq ".jobs[$jci].parameters.args")
  if [[ ( $cmd_args == 'null' ) || ( $cmd_args == '' ) ]]; then
    cmd_args="--update --progress"
  else
    cmd_args="${cmd_args} --progress"
  fi
  cmd_subcmd=$(cat $configfile | yq ".jobs[$jci].parameters.command")
  if [[ ( $cmd_subcmd == 'null' ) || ( $cmd_subcmd == '' ) ]]; then
    cmd_subcmd="copy"
  fi
  # Validate Command
  cmd_program=$(cat $configfile | yq ".jobs[$jci].parameters.program")
  cmd_program=$(echo ${cmd_program,,})
  if [[ ( $cmd_program == 'null' ) || ( $cmd_program == '' ) ]]; then
    cmd_program="rclone"
  elif [[ ( $cmd_program == 'rsync' ) || ( $cmd_program == 'rclone' ) ]]; then
    error_exit "$job_name - rsync is not currently supported"
    #:
  else
    error_exit "$job_name - $cmd_program isn't rsync or rclone, exiting for data safety!" COMMAND
  fi
  # Check for Mirror-Copy and assign command
  cmd_mc=$(cat $configfile | yq ".jobs[$jci].parameters.mirrorcopy")
  if [[ ( $cmd_mc != 'true' ) ]]; then
    if [[ ( $cmd_program == 'rsync' ) ]]; then
      job_cmd="$cmd_program $cmd_subcmd $cmd_args $job_src $job_dest"
    elif [[ ( $cmd_program == 'rclone' )  ]]; then
      job_cmd="$cmd_program $cmd_subcmd $job_src $job_dest $cmd_args; date"
      #job_cmd="echo $option $job_src $job_dest; date"
    fi
  else 
    if [[ ( $cmd_program == 'rsync' ) ]]; then
      job_cmd="$cmd_program $cmd_subcmd $cmd_args $job_src $job_dest; $cmd_program $cmd_subcmd $cmd_args $job_dest $job_src; date"
    elif [[ ( $cmd_program == 'rclone' )  ]]; then
      job_cmd="$cmd_program $cmd_subcmd $job_src $job_dest $cmd_args; $cmd_program $cmd_subcmd $job_dest $job_src $cmd_args; date"
    fi
  fi
}

function validate_name () {
  job_name=$(cat $configfile | yq ".jobs[$jci].name")
  if [[ ( $job_name == 'null' ) || ( $job_name == '' ) ]]; then
    num=$((jci+1))
    error_exit "#$num is missing required parameter" "Name"
  fi
}

function validate_path () {
  job_src_name=$( cat $configfile | yq ".jobs[$jci].pathtypes.source" )
  job_src=$( cat $configfile | yq ".jobs[$jci].paths.source" )
  if [[ ( $job_src_name == 'null' ) || ( $job_src_name == '' ) ]]; then
    job_src_name="local"
  fi
  if [[ $job_src_name == "local" ]]; then
    test_local_path $job_src
  else
    job_src="${job_src_name}:${job_src}"
  fi
  job_dest_name=$( cat $configfile | yq ".jobs[$jci].pathtypes.destination" )
  job_dest=$( cat $configfile | yq ".jobs[$jci].paths.destination" )
  if [[ ( $job_dest_name == 'null' ) || ( $job_dest_name == '' ) ]]; then
    $job_dest_name="local"
  fi
  if [[ $job_dest_name == "local" ]]; then
    test_local_path $job_dest
  else
    job_dest="${job_dest_name}:${job_dest}"
  fi
}

#########################
#       Variables
#########################
config_folder="$HOME/.brb"
configfile="${config_folder}/backups.yaml"

# Dynamic Variables
now=$(date)
job_count=$(cat $configfile | yq '.jobs | length')
user_id=$(id -u $(whoami))
systemd_t_timer_path="/run/user/${user_id}/systemd/transient"
# Job Count Iterator 
jci=0

#########################
#     Program Start
#########################

# TODO: Version Check

echo "BRB Started processing jobs for $(whoami) at $(date)"

# Loop through all the jobs
while [[ $jci < $job_count ]]; do
  # Job Variables
  job_freq=''
  job_freq_type=''
  job_name=''
  job_src=''
  job_src_name=''
  job_dest=''
  job_dest_name=''
  job_cmd=''
  # Validate inputs and assign variables
  validate_job
  # Schedule job if it doesn't exist and hasn't changed
  set_job
  # Increase counter by 1
  ((jci++))
done

echo "BRB Finished processing jobs for $(whoami) at $(date)"
