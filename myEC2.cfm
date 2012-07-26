<!---
ColdFusion-based AWS Console v1.0
Author: David Smith (dcsmith@hotmail.com)
Released: March 2008
License: Apache License, Version 2 (http://www.apache.org/licenses/LICENSE-2.0)
--->

<cftry>

<cfset accessKeyId = "#session.accessKeyID#"> 
<cfset secretAccessKey = "#session.secretAccessKey#">
<cfset ec2 = createObject("component","cfcs.ec2").init(accessKeyId,secretAccessKey)>


<CFHEADER NAME="Expires" VALUE="31 Dec 1990 08:49:37 GMT">
<CFHEADER NAME="Pragma" VALUE="no-cache">
<CFHEADER NAME="cache-control" VALUE="no-cache, no-store, must-revalidate">

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>AWS Console - EC2</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<LINK REL="stylesheet" HREF="scripts/basic.css" SRC="scripts/basic.css">
<LINK REL="stylesheet" HREF="scripts/tabs.css" SRC="scripts/tabs.css">
</head>

<cfoutput>
<body>
<table border="0" width="100%"><tr><td align="left"><h1 style="font-size:38px; color:##666666">My AWS Console</h1></td><td align="right"><a href="http://www.adobe.com/coldfusion" target="_blank"><img src="images/poweredbycf.gif" alt="cf logo" border="0" /></a></td></tr></table>

<div id="header">
    <ul id="primary">
        <li><a href="index.cfm">Home</a></li>
        <li><span>EC2</span></li>
            <ul id="secondary">
                <li><a href="cfcs/ec2.cfc" target="_blank">CFC Explorer</a></li>
                <li><a href="http://docs.amazonwebservices.com/AWSEC2/2007-08-29/DeveloperGuide/" target="_blank">Developer Guide</a></li>
                <li><a href="http://developer.amazonwebservices.com/connect/forum.jspa?forumID=30" target="_blank">Forum</a></li>
            </ul>
        <li><a href="myS3.cfm">S3</a></li>
        <li><a href="mySQS.cfm">SQS</a>
        <li><a href="myDB.cfm">SDB</a>
        </li>
    </ul>
</div>
<div id="main">
<div id="contents">

<cfif IsDefined("url.i")>
	<cfset consoleOutput = #ec2.getConsoleOutput(url.i)#>
	<table cellpadding="2" cellspacing="0" border="1">
	<tr>
		<td><pre>#ToString(ToBinary(consoleOutput.Output.xmlText))#</pre>
	</td>
	</tr>
	</table>
</cfif>

<cfif ISDefined("url.firewall")>
	<cfset ec2.createDefaultCFPolicy()>
</cfif>

<cfif IsDefined("url.i2")>
	<cfdump var="#ec2.getConsoleOutput(url.i2)#">
</cfif>


<cfif IsDefined("form.startInstances")>
	<cftry>
	<cfloop list="#form.ami#" index="j">
		<cfif #Form["start" & j]# eq 0 or #Form["start" & j]# eq "">
		<cfelse>
			<cfset myArray = '"#j#","1","#Form["start" & j]#","#Form["keyName" & j]#","","","public","#Form["ectype" & j]#"'>
			<cfset createInstances = ec2.runInstances("#j#","1","#Form["start" & j]#","#Form["keyName" & j]#","","","public","#Form["ectype" & j]#")>
		</cfif>
	</cfloop>
	<cfcatch type="Any"><h2><font color="red">#cfcatch.detail#</font></h2></cfcatch></cftry>
</cfif>


<cfif IsDefined("form.manageInstances")>
	<cfloop list="#form.instanceList#" index="h">
	<cftry>
		<cfif NOT IsDefined(#Form["reboot" & h]#)>Reboot: #h# <cfset rebootInstances = ec2.rebootInstances("#h#")><br></cfif>
	<cfcatch></cfcatch>
	</cftry>
	</cfloop>
	<cfloop list="#form.instanceList#" index="h">
	<cftry>
		<cfif NOT IsDefined(#Form["terminate" & h]#)>Terminate: #h#"  <cfset terminateInstances = ec2.terminateInstances("#h#")><br></cfif>
	<cfcatch></cfcatch>
	</cftry>
	</cfloop>
</cfif>

<cfset allSecurityGroups = ec2.describeSecurityGroups()>
<cfset allKeypairs = ec2.describeKeypairs()>

<h2>My Images</h2>

<cfset allImages = ec2.describeImages(#allSecurityGroups[1].OwnerID#)>

<form action="#cgi.script_name#" method="post" name="form1">
<table cellpadding="2" cellspacing="0" border="1">
<th>AMI ID</th><th>Image Name</th><th>State</th><th>Is Public?</th><th>Owner</th><th>Start More?</th>
<cfloop from="1" to="#arrayLen(allImages)#" index="i">
		<tr>
		<td nowrap="nowrap">#allImages[i].ImageID#</td>
		<td>#allImages[i].ImageLocation#</td>
		<td>#allImages[i].ImageState#</td>
		<td>#allImages[i].IsPublic#</td>
		<td><select name="ImageOwnerID#allImages[i].ImageID#" size="1"><option value="#allImages[i].ImageOwnerID#">#allImages[i].ImageOwnerID#</option></select></td>
		<td nowrap="nowrap">Start <input type="text" name="start#allImages[i].ImageID#" size="1" maxlength="1"> <input type="Radio" name="ECtype#allImages[i].ImageID#" value="m1.small" checked> small <input type="Radio" name="ECtype#allImages[i].ImageID#" value="m1.large"> large <input type="Radio" name="ECtype#allImages[i].ImageID#" value="m1.xlarge"> xlarge <select name="keyName#allImages[i].ImageID#" size="1"><option value="#allKeypairs[1].keyName#">#allKeypairs[1].keyName#</option></select> <input type="hidden" name="ami" value="#allImages[i].ImageID#"></td>
		</tr>
</cfloop>
<tr><td colspan="6" align="right"><input type="submit" name="startInstances" value="Execute" onclick="return confirm('Are you sure?')"></td></tr>
</table>
</form>

<cfset allInstances = ec2.describeInstances()>
<cfif #arrayLen(allInstances)#>

<h2>My Instances (<a href="myEC2.cfm">refresh</a>)</h2>

<form action="#cgi.script_name#" method="post" name="form2">
<table cellpadding="2" cellspacing="0" border="1">
<th>Instance ID</th><th>State</th><th>DNS</th><th>Launch Time</th><th>Run Time</th><th>Size</th><th>Cost</th><th>View</th><th>Action</th>
<cfset totCost = 0>
<cfloop from="1" to="#arrayLen(allInstances)#" index="i">

	<cfloop from="1" to="#arrayLen(allInstances[i].instancesSet)#" index="j">
	<cfset zuluLocalDate = #SpanExcluding(allInstances[i].instancesSet[j].LaunchTime, "T")#>
	<cfset zuluLocalTime = #Mid(SpanExcluding(allInstances[i].instancesSet[j].LaunchTime, "."), 12, 8)#>
	<cfset newDate = "#DateFormat(zuluLocalDate)# #TimeFormat(zuluLocalTime, "hh:mm:ss tt")#">
	<cfset newDate2 = "#DateConvert("utc2local", newDate)#">
		<tr>
		<td>#allInstances[i].instancesSet[j].InstanceID#</td>
		<td
		<cfif #allInstances[i].instancesSet[j].InstanceState.name# is "pending"> bgcolor="lightyellow"
		<cfelseif #allInstances[i].instancesSet[j].InstanceState.name# is "running"> bgcolor="lightgreen"
		<cfelseif #allInstances[i].instancesSet[j].InstanceState.name# is "shutting-down"> bgcolor="orange"
		<cfelseif #allInstances[i].instancesSet[j].InstanceState.name# is "terminated"> bgcolor="pink"
		</cfif>>#allInstances[i].instancesSet[j].InstanceState.name#</td>
		<td><a href="http://#allInstances[i].instancesSet[j].DNSName#" target="_blank" title="opens new window">#allInstances[i].instancesSet[j].DNSName#</a></td>
		<td>#DateFormat(newDate2)# @ #TimeFormat(newDate2)#</td>
		<td align="center">#DateDiff("h", newDate2, Now())#hrs  <cfset diff = "#DateDiff("h", newDate2, Now()+1/24)#"></td>
		<td>#allInstances[i].instancesSet[j].InstanceType#</td>
		<td><cfif #allInstances[i].instancesSet[j].InstanceType# eq "m1.small">#DollarFormat(Evaluate(diff*.10))#	<cfset totCost = totCost + "#Evaluate(diff*.10)#">
		<cfelseif #allInstances[i].instancesSet[j].InstanceType# eq "m1.large">#DollarFormat(Evaluate(diff*.40))#	<cfset totCost = totCost + "#Evaluate(diff*.40)#">
		<cfelseif #allInstances[i].instancesSet[j].InstanceType# eq "m1.xlarge">#DollarFormat(Evaluate(diff*.80))#	<cfset totCost = totCost + "#Evaluate(diff*.80)#"></cfif></td>
		<td><a href="#cgi.script_name#?i=#URLEncodedFormat(allInstances[i].instancesSet[j].InstanceID)#">Console</a> | <a href="#cgi.script_name#?i2=#URLEncodedFormat(allInstances[i].instancesSet[j].InstanceID)#">Struct</a></td>
		<td><input type="radio" name="reboot#allInstances[i].instancesSet[j].InstanceID#" value="reboot"> reboot <input type="radio" name="terminate#allInstances[i].instancesSet[j].InstanceID#" value="terminate"> Terminate  <input type="hidden" name="instanceList" value="#allInstances[i].instancesSet[j].InstanceID#"</td>
		</tr>
	</cfloop>
</cfloop>
<tr><td colspan="7" align="right"><strong>#DollarFormat(totCost)#</strong></td><td>&nbsp;</td><td align="right"><input type="submit" name="manageInstances" value="Execute" onclick="return confirm('Are you sure?')"></td></tr>
</table>
</form>
</cfif>

<br />
<h2>My Owner ID</h2>

<table cellpadding="2" cellspacing="0" border="0">
<tr>
	<td>#allSecurityGroups[1].OwnerID#</td>
</tr>
</table><br />

<h2>Security Groups</h2>
<table cellpadding="2" cellspacing="0" border="0">
<cfloop array="#ec2.describeSecurityGroups()#" index="x">
<tr>
	<td>#x.groupName#</td>
</tr>
</cfloop>
</table><br />
<a href="#cgi.script_name#?firewall=true">Update default security group with standard permissions</a><br/>
<h2>My Keypairs</h2>




<cfif NOT ArrayLen(allKeypairs)>No keypairs defined<cfelse>
<table cellpadding="2" cellspacing="0" border="0">
<tr>
	<td>#allKeypairs[1].keyName#</td>
</tr>
</table>
</cfif>

<p><a href="#cgi.SCRIPT_NAME#">Refresh</a></p>
</cfoutput>
<cfcatch type="Any"><cfinclude template="error.cfm"></cfcatch>
</div>
</div>
</body></html></cftry>

