<!--- 3 hour timeout --->
<cfapplication name="aws" sessionTimeout=#CreateTimeSpan(0, 3, 0, 0)# sessionManagement="Yes">

<!--- session variables used to initiate all components ---> 
<cfparam name="session.accessKeyID" default="">
<cfparam name="session.secretAccessKey" default="">
