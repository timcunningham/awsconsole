<!---
ColdFusion-based AWS Console v1.0
Author: David Smith (dcsmith@hotmail.com)
Released: March 2008
License: Apache License, Version 2 (http://www.apache.org/licenses/LICENSE-2.0)
--->

<CFHEADER NAME="Expires" VALUE="31 Dec 1990 08:49:37 GMT">
<CFHEADER NAME="Pragma" VALUE="no-cache">
<CFHEADER NAME="cache-control" VALUE="no-cache, no-store, must-revalidate">

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>AWS Console - Home</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<LINK REL="stylesheet" HREF="scripts/basic.css" SRC="scripts/basic.css">
<LINK REL="stylesheet" HREF="scripts/tabs.css" SRC="scripts/tabs.css">
</head>

<body>
<table border="0" width="100%"><tr><td align="left"><h1 style="font-size:38px; color:#666666">My AWS Console</h1></td><td align="right"><a href="http://www.adobe.com/coldfusion" target="_blank"><img src="images/poweredbycf.gif" alt="cf logo" border="0" /></a></td></tr></table>

<div id="header">
    <ul id="primary">
        <li><span>Home</span></li>
            <ul id="secondary">
                <li><a href="http://www.amazon.com/aws" target="_blank">AWS Home Page</a></li>
                <li><a href="http://aws.typepad.com/" target="_blank">AWS Blog</a></li>                
                <li><a href="http://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=activity-summary" target="_blank">Your Account Activity</a></li>
                <li><a href="http://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key" target="_blank">Your Identifiers</a></li>
            </ul>
        <li><a href="myEC2.cfm">EC2</a></li>
        <li><a href="myS3.cfm">S3</a></li>
        <li><a href="mySQS.cfm">SQS</a>
        <li><a href="myDB.cfm">SDB</a>
        </li>
    </ul>
</div>
<div id="main">
<div id="contents">

<cfif IsDefined("form.accessKeyID")>
	<cfset session.accessKeyID = "#TRIM(form.accessKeyId)#">
	<cfset session.secretAccessKey = "#TRIM(form.secretAccessKey)#">
</cfif>

<cfif IsDefined("url.sessionExpire")>
	<cfset StructClear(session)>
</cfif>

<cfif IsDefined("session.accessKeyID") AND session.accessKeyID neq "">
	<p>Your AWS identifiers are below.  They will expire in 3 hours or you can <a href="index.cfm?sessionExpire=">expire them now</a>.</p>
	<cfoutput>
	<p><strong>AccessKey ID:</strong> #session.accessKeyID#<br>
	<strong>Secret AccessKey ID:</strong> #session.secretAccessKey#</p>
	</cfoutput>
<cfelse>
	<p>To get started, please enter your AWS identifiers below.</p>
		
	<cfform action="index.cfm" method="post">
	<table>
	<tr>
		<td align="right"><strong>AccessKey ID:</strong></td>
		<td><cfinput type="Text" name="accessKeyId" required="Yes" message="You must enter an Access Key value." value="" size="30"></td>
	</tr>
	<tr>
		<td><strong>Secret AccessKey ID:</strong></td>
		<td><cfinput type="text" name="secretAccessKey" required="Yes" message="You must enter a Secret Key value." value="" size="50"></td>
	</tr>
	</table>
	<br><input type="submit" name="submit" value="Submit">
	</cfform>
</cfif>

</div>
</div>
</body></html>