#!/bin/bash

df_jobs="$(gcloud dataflow jobs list --filter="baniaspipeline" --status="active" | awk 'FNR > 1 {print $1}')"

for job_id in "${df_jobs[@]}";
do
 gcloud dataflow jobs drain $job_id
 while :
 do
  job_status="$(gcloud dataflow jobs show $job_id | awk 'FNR == 5 {print $2}')"
  echo $job_status
  if [ ${job_status} = "Drained" ]
      then
        echo "Job id: ${job_id} found with status: "${job_status}" status, proceeding to the next step."
        break
      fi
      echo "Job id: ${job_id} found with status: "${job_status}". Wating for the job to be drained, next check in 30 seconds."
      sleep 30
 done
done