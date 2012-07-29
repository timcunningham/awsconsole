<!---
ColdFusion-based AWS Console v1.0
Author: David Smith (dcsmith@hotmail.com)
Released: March 2008
License: Apache License, Version 2 (http://www.apache.org/licenses/LICENSE-2.0)
--->


<cftry>

<cfset awsAccessKeyId = "#session.accessKeyID#"> 
<cfset secretAccessKey = "#session.secretAccessKey#">
<cfset sqs = CreateObject("component", "cfcs.sqs").init(awsAccessKeyId, secretAccessKey)/>

<CFHEADER NAME="Expires" VALUE="31 Dec 1990 08:49:37 GMT">
<CFHEADER NAME="Pragma" VALUE="no-cache">
<CFHEADER NAME="cache-control" VALUE="no-cache, no-store, must-revalidate">

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>AWS Console - SQS</title>
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
        <li><a href="myS3.cfm">S3</a></li>
        <li><span>SQS</span>
            <ul id="secondary">
                <li><a href="cfcs/sqs.cfc" target="_blank">CFC Explorer</a></li>
                <li><a href="http://docs.amazonwebservices.com/AWSSimpleQueueService/2008-01-01/SQSDeveloperGuide/" target="_blank">Developer Guide</a></li>
                <li><a href="http://developer.amazonwebservices.com/connect/forum.jspa?forumID=12" target="_blank">Forum</a></li>
            </ul>
        </li>
        <li><a href="myDB.cfm">SDB</a>
    </ul>
</div>
<div id="main">
<div id="contents">

<cfparam name="action" default=""/>
<cfswitch expression="#action#">
	<cfcase value="createQueue">
		<cfset sqs.createQueue(Form.queueName)/>
	</cfcase>
	<cfcase value="deleteQueue">
		<cfset sqs.deleteQueue(Url.queueUri)/>
	</cfcase>
	<cfcase value="sendMessage">
		<cfset sqs.sendMessage(Form.queueUri, Form.message)/>
	</cfcase>
	<cfcase value="receiveMessage">
		<cfset msg = sqs.receiveMessage(Url.queueUri, Url.maxNumberOfMessages)/>
		<cfdump var="#msg#"/>
            <small>NOTE: Due to the distributed nature of the queue, a weighted random set of machines is sampled on a ReceiveMessage call. That means only the messages on the sampled machines are returned. If the number of messages in the queue is small (less than 1000), it is likely you will get fewer messages than you requested per ReceiveMessage call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular ReceiveMessage response; in which case you should repeat the request.</small><br /><br />
	</cfcase>
	<cfcase value="getQueueAttributes">
		<cfdump var="#sqs.getQueueAttributes(Url.queueUri, Url.attributeName)#"/>
	</cfcase>
</cfswitch>

<cfoutput>
	<cfset queues = sqs.listQueues()/>
	<cfset queueCount = ArrayLen(queues)/>
	
	<cfif queueCount>
    <h2>My Queues</h2>
	
	<table cellpadding="2" cellspacing="0" border="1">
		<thead>
			<tr>
				<th>Queue URL</th>
				<th>
					Actions
				</th>
			</tr>
		</thead>
		<tbody>
			<cfloop index="i" from="1" to="#queueCount#">
				<tr>
					<td>#queues[i]#</td>
					<td>
						<a href="#CGI.SCRIPT_NAME#?action=getQueueAttributes&amp;queueUri=#queues[i]#&amp;attributeName=All">Get Attributes</a> |
						<a href="#CGI.SCRIPT_NAME#?action=deleteQueue&amp;queueUri=#queues[i]#" onclick="return confirm('Are you sure?')">Delete Queue</a> |
						<a href="#CGI.SCRIPT_NAME#?action=receiveMessage&amp;queueUri=#queues[i]#&maxNumberOfMessages=100">Receive Message</a>
					</td>
				</tr>
			</cfloop>
		</tbody>
	</table><br />
    </cfif>

	<h2>Create Queue</h2>

	<form action="#CGI.SCRIPT_NAME#" method="post">
		<label for="queueName">Queue name:</label> <input type="text" name="queueName" id="queueName"/> <input type="submit" value="Create Queue"/><br />
        <em><small>Constraints: Maximum 80 characters; alphanumeric characters, hyphens (-), and underscores (_) are allowed</small></em>
		<input type="hidden" name="action" value="createQueue"/>		
	</form>
	
	<br />
    <h2>Send Message</h2>
	
	<form action="#CGI.SCRIPT_NAME#" method="post">
		<label for="queueUri">Queue:</label>
		<select name="queueUri" id="queueUri">
			<cfloop index="i" from="1" to="#queueCount#">
				<option value="#queues[i]#">#ListLast(queues[i], "/")#</option>
			</cfloop>
		</select>
		<br/><br/>
		<label for="message">Message:</label>
		<br/>
		<textarea name="message" id="message" rows="10" cols="60"></textarea>
		<br/>
		<input type="hidden" name="action" value="sendMessage"/>
		<input type="submit" value="Send"/>
	</form>

<br /><a href="#cgi.SCRIPT_NAME#">Refresh</a>

</cfoutput>
<cfcatch type="Any"><cfinclude template="error.cfm"></cfcatch>
</div>
</div>
</body></html></cftry>


