<!---
ColdFusion-based AWS Console v1.0
Author: David Smith (dcsmith@hotmail.com)
Released: March 2008
License: Apache License, Version 2 (http://www.apache.org/licenses/LICENSE-2.0)
--->

<cftry>

<cfset accessKeyId = "#session.accessKeyID#"> 
<cfset secretAccessKey = "#session.secretAccessKey#">
<cfset s3 = createObject("component","cfcs.s3").init(accessKeyId,secretAccessKey)>

<CFHEADER NAME="Expires" VALUE="31 Dec 1990 08:49:37 GMT">
<CFHEADER NAME="Pragma" VALUE="no-cache">
<CFHEADER NAME="cache-control" VALUE="no-cache, no-store, must-revalidate">

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>AWS Console - S3</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<LINK REL="stylesheet" HREF="scripts/basic.css" SRC="scripts/basic.css">
<LINK REL="stylesheet" HREF="scripts/tabs.css" SRC="scripts/tabs.css">
</head>

<body>
<table border="0" width="100%"><tr><td align="left"><h1 style="font-size:38px; color:#666666">My AWS Console</h1></td><td align="right"><a href="http://www.adobe.com/coldfusion" target="_blank"><img src="images/poweredbycf.gif" alt="cf logo" border="0" /></a></td></tr></table>

<div id="header">
    <ul id="primary">
        <li><a href="index.cfm">Home</a></li>
        <li><a href="myEC2.cfm">EC2</a></li>
        <li><span>S3</span></li>
            <ul id="secondary">
                <li><a href="cfcs/s3.cfc" target="_blank">CFC Explorer</a></li>
                <li><a href="http://docs.amazonwebservices.com/AmazonS3/2006-03-01/" target="_blank">Developer Guide</a></li>
                <li><a href="http://developer.amazonwebservices.com/connect/forum.jspa?forumID=24" target="_blank">Forum</a></li>
            </ul>
        <li><a href="mySQS.cfm">SQS</a>
        <li><a href="myDB.cfm">SDB</a>
        </li>
    </ul>
</div>
<div id="main">
<div id="contents">

<cfparam name="url.b" default="">

<cfif isDefined("form.createBucket")>
	<cfif compare(url.b,'')>
		<cfset form.bucketName = url.b & "/" & form.bucketName>
	</cfif>
	<cfset s3.putBucket(form.bucketName,form.acl,form.storage)>
<cfelseif isDefined("form.uploadFile")>
	<cffile action="upload" filefield="objectName" destination= "#ExpandPath('.')#" nameconflict="makeunique" mode="666">
	<cfset s3.putObject(url.b,file.serverFile,file.contentType)>
	<cffile action="delete" file="#ExpandPath("./#file.serverFile#")#">
<cfelseif isDefined("url.db")>
	<cfset s3.deleteBucket(url.db)>
<cfelseif isDefined("url.do")>
	<cfset s3.deleteObject(url.b,url.do)>
<cfelseif isDefined("url.vo")>
	<cfset timedLink = s3.getObject(url.b,url.vo)>
	<cfoutput><table border="1" cellspacing="0" cellpadding="4" bgcolor="ffffco"><tr><td><a href="#timedLink#">#timedLink#</a></td></tr></table></cfoutput>
</cfif>

<cfif compare(url.b,'')>
	<cfset allContents = s3.getBucket(url.b)>
	<cfoutput>
	<h2><a href="myS3.cfm">My Buckets</a> > #url.b#</h2>
	<table cellpadding="2" cellspacing="0" border="1">
	<cfloop from="1" to="#arrayLen(allContents)#" index="i">
	<tr><td>#allContents[i].Key#</td><td>#allContents[i].LastModified#</td><td>#NumberFormat(allContents[i].Size)#</td><td><a href="#cgi.script_name#?b=#URLEncodedFormat(url.b)#&vo=#URLEncodedFormat(allContents[i].Key)#">Get Link</a></td><td><a href="#cgi.script_name#?b=#URLEncodedFormat(url.b)#&do=#URLEncodedFormat(allContents[i].Key)#" onclick="return confirm('Are you sure?')">Delete</a></td></tr>
	</cfloop>
	</table><br />
	<form action="#cgi.script_name#?b=#url.b#" method="post" enctype="multipart/form-data">
	<input type="file" name="objectName" size="30" />
	<input type="submit" name="uploadFile" value="Upload File" />
	</form>	
	<a href="#cgi.script_name#">List All Buckets</a>
	</cfoutput>	
<cfelse>
	<!--- get all buckets --->
	<cfset allBuckets = s3.getBuckets()>
	<cfoutput>
	<h2>My Buckets</h2>
	<table cellpadding="2" cellspacing="0" border="1">
	<cfloop from="1" to="#arrayLen(allBuckets)#" index="i">
	<tr><td>#allBuckets[i].Name#</td><td>#allBuckets[i].CreationDate#</td><td><a href="#cgi.script_name#?b=#URLEncodedFormat(allBuckets[i].Name)#">View</a></td><td><a href="#cgi.script_name#?db=#URLEncodedFormat(allBuckets[i].Name)#" onclick="return confirm('Are you sure?')">Delete</a></td></tr>
	</cfloop>
	</table><br />
	<form action="#cgi.script_name#?b=#url.b#" method="post">
	<input type="text" name="bucketName" size="30" />
	<select name="acl">
		<option value="private">Private</option>
		<option value="public-read">Public-Read</option>
		<option value="public-read-write">Public-Read-Write</option>
		<option value="authenticated-read">Authenticated-Read</option>
	</select>
	<select name="storage">
		<option value="US">United States</option>
		<option value="EU">Europa</option>
	</select>
	<input type="submit" name="createBucket" value="Create Bucket" />
	</form>
    
    <br /><a href="#cgi.SCRIPT_NAME#">Refresh</a>
    
	</cfoutput>
</cfif>
<cfcatch type="Any"><cfinclude template="error.cfm"></cfcatch>
</div>
</div>
</body></html></cftry>