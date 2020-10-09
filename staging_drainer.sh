#!/bin/bash

df_working_region=$1
project_id=$2

df_jobs=($(gcloud dataflow jobs list --filter="baniaspipeline" --status="active" --region="$df_working_region" --project="$project_id" --format='value(JOB_ID)'))

echo "job found: ${#df_jobs[@]}"

if [ ${#df_jobs[@]} -gt 1 ]; then
  echo "Found more then one active Dataflow job, please cancel or drain irrelevant jobs and try again."
  exit 1

elif [ ${#df_jobs[@]} -eq 0 ]; then
  echo "There are no active job has been found, please run new dataflow job."
  exit 1
fi

echo "One active job has been detected: ${df_jobs[0]}, preparing to drain the job."

# Get the job_id
job_id=${df_jobs[0]}

# Drain command
gcloud dataflow jobs drain "$job_id" --region="$df_working_region" --project="$project_id"

# Draining loop

while :
 do
  job_status="$(gcloud dataflow jobs show "$job_id" --region=df_working_region --project="$project_id" --format='value(STATE)')"
  echo "$job_status"
  if [ "${job_status}" = "Drained" ]
      then
        echo "Job id: ${job_id} found with status: ""${job_status}"", the drain process has been completed."
        break
      fi
      echo "Job id: ${job_id} found with status: ""${job_status}"". Waiting for the job to be drained, next check in 10 seconds."
      sleep 10
 done