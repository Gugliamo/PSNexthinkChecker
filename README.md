# PSNexthinkChecker
A PowerShell script with daily Queries using NXQL to pull lists of computer names from Nexthink with a loop to check for online activity to push commands as jobs.

When executing winAutoUpdateListV4_getJobRewrite.ps1, a dialogue window will prompt you for your Nexthink login credentials. On success, the script will run 24/7. On initialization, the script will query Nexthink for a list of computers with Missing OS Updates for the full available time-period. The script will also query for a list of computers which haven’t had Windows Updates between 16 and 37 days. The two lists will be combined and printed out for the log. 

Next, the script will use the previously created list of computers needing Windows Updates to check if each computer is online. If it’s online, the script will invoke a command to execute the Driver script which calls for the WSUS server to push any outstanding updates and log the entire process. The command will be executed as a job (PowerShell threads) in the background. The script will periodically check whether a job is complete and will print the results before continuing to check for online activity. 

The main script will query for a new list of computers around midnight every night, creating a new log file -- fully automating the entire process.
