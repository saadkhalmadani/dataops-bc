> crontab -e
and add this below:
   0 */6 * * * /home/saadkh/dataops-bc/cron_job_runner.sh >> /home/saadkh/dataops-bc/cron.log 2>&1