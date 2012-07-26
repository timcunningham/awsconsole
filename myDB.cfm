<!---
ColdFusion-based AWS Console v1.0
Author: David Smith (dcsmith@hotmail.com)
Released: March 2008
License: Apache License, Version 2 (http://www.apache.org/licenses/LICENSE-2.0)
--->

<cftry>

<cfset accessKeyId = "#session.accessKeyID#"> 
<cfset secretAccessKey = "#session.secretAccessKey#">
<cfset db = createObject("component","cfcs.db").init(accessKeyId,secretAccessKey)>

<CFHEADER NAME="Expires" VALUE="31 Dec 1990 08:49:37 GMT">
<CFHEADER NAME="Pragma" VALUE="no-cache">
<CFHEADER NAME="cache-control" VALUE="no-cache, no-store, must-revalidate">

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>AWS Console - SimpleDB</title>
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
        <li><a href="mySQS.cfm">SQS</a>
        <li><span>SDB</span></li>
            <ul id="secondary">
            	<cfoutput>
                <li><a href="cfcs/db.cfc" target="_blank">CFC Explorer</a></li>
                <li><a href="http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/" target="_blank">Developer Guide</a></li>
                <li><a href="http://developer.amazonwebservices.com/connect/forum.jspa?forumID=38" target="_blank">Forum</a></li>
                </cfoutput>
            </ul>

        </li>
    </ul>
</div>
<div id="main">
<div id="contents">

<cfset listDomains = db.listDomains()>

<cfparam name="action" default=""/>
<cfswitch expression="#action#">
	<cfcase value="query">
		<cfset domainContents = db.query(url.domainName)>
	</cfcase>
    <cfcase value="getAttributes">
		<cfset itemContents = db.getAttributes(url.domainName, url.item)>
	</cfcase>
    <cfcase value="deleteAttributes">
		<cfset deleteItem = db.deleteAttributes(url.domainName, url.item)>
        <cfset domainContents = db.Query(url.domainName)>
	</cfcase>
    <cfcase value="deleteDomain">
		<cfset deleteDomain = db.deleteDomain(url.domainName)>
	</cfcase>
</cfswitch>


<cfif IsDefined("form.createDomain")>
<cfset createDomain = db.createDomain(form.domainName)>
</cfif>

<!---<cfdump var="#form#">--->

<cfif IsDefined("form.query")>
	<cfset queryExpression = "['#form.name#' #form.operator# '#form.value#']">
    <cfset queryResult = db.Query("#form.domainName#", "#queryExpression#")>
    <cfdump var="#queryResult#">
</cfif>

<cfif IsDefined("form.submit")>

	<cfset attributeNameList="">
    <cfset attributeValueList="">
    <cfset attributeReplaceList="">
    <cfparam name="domainName" default="">
    <cfparam name="form.fieldnames" default="">
    
    <cfloop from="1" to="#ListLen(form.fieldnames)#" index="i">
    <cfset field = ListGetAt(form.fieldnames, #i#)>
    
    <!--- Check for empty values when UPDATING (updating sends the Replace attribute with every name/value pair).  If empty value string, remove the Replace attribute. --->
    <!--- This stuff could probably be moved to the CFC --->
    <cfif i-1><cfset fieldBefore = ListGetAt(form.fieldnames, "#i-1#")></cfif>
    
    <cfif field eq "domainname" or field eq "itemname" or field eq "submit"><cfelse>
        <cftry>
            <cfset attributeNameList = ListAppend(attributeNameList, "#Lcase(field)#")>
            <cfset attributeValueList = ListAppend(attributeValueList, "#Form[field]#", "|")>
        <cfcatch type="Any"><p><font color="red"><cfoutput>#cfcatch.detail#</cfoutput></font></p></cfcatch></cftry>
    </cfif>
    </cfloop>
    
    <cfoutput>   
    <cfset putAttributes = db.putAttributes("#attributeNameList#", "#attributeValueList#", "#form.itemName#", "#form.domainName#")>
    <p>Success putting attributes!  Box Usage: #putAttributes#<br /><br />
    </cfoutput>
    
</cfif>

<cfoutput>

<cfif IsDefined("url.item") AND #url.action# NEQ "deleteAttributes">

    <h2><a href="#cgi.SCRIPT_NAME#">My Domains</a> > <a href="#cgi.SCRIPT_NAME#?action=query&domainName=#url.domainName#">#url.domainName#</a> > #url.item#</h2>

	<cfif NOT IsDefined("url.update")>
    
    <p><strong>Item Attributes:</strong><br />
    <!---Use this if you want to order the output of the name fields:  <cfset itemContents = db.arrayOfStructsSort(itemContents, "name")>--->
    <cfloop from="1" to="#arrayLen(itemContents)#" index="i">
    #itemContents[i].Name# = #itemContents[i].Value#<br />
    </cfloop>
    
    <cfelseif IsDefined("url.update")>

   	    <cfset items = db.getAttributes("#url.domainName#","#url.item#")>
		
        <p>
        <form action="#cgi.script#" method="post">    
        <table cellpadding="4" cellspacing="0" border="1">        
        <tr><td>Item:</td><td>#url.item#</td></tr>
        <cfloop from="1" to="#arrayLen(items)#" index="j">
            <tr><td>#items[j].Name#:</td><td>	<input type="text" name="#items[j].Name#" value="#items[j].Value#"/> <input type="hidden" name="Attribute.#j#.Replace" value="true" /></td></tr>
        </cfloop>
        </table><br />
        <input type="hidden" name="domainName" value="#url.domainName#" />
        <input type="hidden" name="itemName" value="#url.item#" />
        <input type="submit" name="submit" value="Update Record!" />
        </form>
        </p>


<!---  Alternately, you can use the code below if you want to set up a "query of queries" and handle the data in a more typical way

    	<!--- We'll use these columns to populate our cfquery below (taking a more traditional approach, as if we were querying a RDBMS) --->
		<cfset users = QueryNew("userid, fname, lname, org, city, state, zip, email, date, memo", "varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar")>

		<!--- Now populate the query so we can manage data in a more familiar way; this is especially helpful when using forms --->
		<cfset addrow = QueryAddRow(users)>
       	<cfset populateQuery = QuerySetCell(users, "userid", "#url.item#")>
        <cfloop from="1" to="#arrayLen(items)#" index="j">
        	<cfset populateQuery = QuerySetCell(users, "#items[j].Name#", "#items[j].Value#")>
        </cfloop>

        <!--- There would be no way to hard code the form below with the layout you want if returning SimpleDB results alone --->
        <cfloop query="users">
            <cfform action="#cgi.script#" method="post">
            <table cellpadding="4" cellspacing="0" border="1">        
            <tr><td>UserID:</td><td>#users.userid#</td></tr>
            <tr><td>First Name:</td><td>	<cfinput type="text" name="fname" value="#users.fname#" required="yes" message="You must at least enter a first name." /> 			<input type="hidden" name="Attribute.1.Replace" value="true" /></td></tr>
            <tr><td>Last Name:</td><td>		<input type="text" name="lname" value="#users.lname#" /> 			<input type="hidden" name="Attribute.2.Replace" value="true" /></td></tr>
            <tr><td>Organization:</td><td>	<input type="text" name="org" value="#users.org#" /> 				<input type="hidden" name="Attribute.3.Replace" value="true" /></td></tr>
            <tr><td>City:</td><td>			<input type="text" name="city" value="#users.city#" /> 				<input type="hidden" name="Attribute.4.Replace" value="true" /></td></tr>
            <tr><td>State:</td><td>			<input type="text" name="state" value="#users.state#" /> 			<input type="hidden" name="Attribute.5.Replace" value="true" /></td></tr>
            <tr><td>Zip:</td><td>			<input type="text" name="zip" value="#users.zip#" /> 				<input type="hidden" name="Attribute.6.Replace" value="true" /></td></tr>
            <tr><td>Email:</td><td>			<input type="text" name="email" value="#users.email#" /> 			<input type="hidden" name="Attribute.7.Replace" value="true" /></td></tr>
            <tr><td>Date:</td><td>			<input type="text" name="date" value="#users.date#" /> 				<input type="hidden" name="Attribute.8.Replace" value="true" /></td></tr>
            <tr><td>Memo:</td><td>			<textarea name="memo" cols="40" rows="10">#users.memo#</textarea> 	<input type="hidden" name="Attribute.9.Replace" value="true" /></td></tr>
            </table>
            <br />
            <input type="hidden" name="domainName" value="#url.domainName#" />
            <input type="hidden" name="itemName" value="#users.userid#" />
            <input type="submit" name="submit" value="Update Record!" />
            </cfform>
        </cfloop>
--->
    </cfif>


<cfelseif IsDefined("url.domainName") AND #url.action# NEQ "deleteDomain" AND NOT IsDefined("url.updateItem")>

    <h2><a href="#cgi.SCRIPT_NAME#">My Domains</a> > #url.domainName#</h2>

	<form action="#cgi.script#" method="post">
    <p>Query where <input type="text" name="name" value="" size="5" />
    <select name="operator" size="1">
    	<option value="=">=</option>
        <option value="!=">!=</option>
        <option value=">">></option>
        <option value=">=">>=</option>
        <option value="<"><</option>
        <option value="<="><=</option>
        <option value="starts-with">starts-with</option>    
    </select>
    <input type="hidden" name="domainName" value="#url.domainName#" />
    <input type="text" name="value" value="" size="30" /> <input type="submit" name="query" value="Go!" /> <small>(case sensitive)</small>
    </p>
    </form>

    <p><strong>Items:</strong><br />
    
    <cfloop from="1" to="#arrayLen(domainContents)#" index="i">
	
    	<cfset itemName = "#domainContents[i].itemName#">
        <cfset items = db.getAttributes("#url.domainName#","#domainContents[i].itemName#")>
        <!---Use this if you want to order the output of the name fields:  <cfset items = db.arrayOfStructsSort(items, "name")>--->

        <a href="#cgi.SCRIPT_NAME#?action=getAttributes&item=#domainContents[i].itemName#&domainName=#url.domainName#"><strong>#itemName#</strong></a> [<a href="#cgi.SCRIPT_NAME#?action=deleteAttributes&item=#domainContents[i].itemName#&domainName=#url.domainName#" onclick="return confirm('Are you sure? May take a few seconds to propagate.')">delete</a>] [<a href="#cgi.SCRIPT_NAME#?action=query&domainName=#url.domainName#&item=#domainContents[i].itemName#&update=">update</a>]<br />

        <ul>
            <cfloop from="1" to="#arrayLen(items)#" index="i">
                #items[i].Name# = #items[i].Value#<br />
            </cfloop>
        </ul>
    
	</cfloop>

<cfelse>

<h2>My Domains</h2>
<cfloop from="1" to="#ArrayLen(listDomains)#" index="i">
<a href="#cgi.SCRIPT_NAME#?action=query&domainName=#listDomains[i].domainName#"><strong>#listDomains[i].domainName#</strong></a> [<a href="#cgi.SCRIPT_NAME#?action=deleteDomain&domainName=#listDomains[i].domainName#" onclick="return confirm('Are you sure?  May take a few seconds to propagate.')">delete</a>]<br />
</cfloop>
<cfform action="#cgi.script#" method="post">
<p>Create a new domain?<br />
<cfinput type="text" name="domainName" value="" required="yes" message="You must enter something."> <input type="submit" name="createDomain" value="Go!" /><small> May take a few seconds to display due to <a href="http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/SDB_Glossary.html" target="_blank" title="opens new window">eventual consistency</a>. [<a href="#cgi.SCRIPT_NAME#">Refresh</a>]</small>
</cfform></p>

<cfform action="#cgi.script#" method="post">

<h2>Submit Some Test Data</h2>

<p><table cellpadding="4" cellspacing="0" border="1">
<tr><td>Domain Name (i.e., table):</td><td><cfselect name="domainName" size="1" required="yes" message="You must create a domain to pass data."><cfloop from="1" to="#ArrayLen(listDomains)#" index="i"><option value="#listDomains[i].domainName#">#listDomains[i].domainName#</option></cfloop></cfselect></td></tr>
<tr><td>Item Name (i.e., primaryID):</td><td><input type="text" name="itemName" value="#createUUID()#" size="50" /></td></tr>
<tr><td>First Name:</td><td>		<cfinput type="text" name="fname" value="" required="yes" message="You must at least enter a first name." /></td></tr>
<tr><td>Last Name:</td><td>			<input type="text" name="lname" value="" /></td></tr>
<tr><td>Organization:</td><td>		<input type="text" name="org" value="" /></td></tr>
<tr><td>City:</td><td>				<input type="text" name="city" value="" /></td></tr>
<tr><td>State:</td><td>				<input type="text" name="state" value="" /></td></tr>
<tr><td>Zip:</td><td>				<input type="text" name="zip" value="" /></td></tr>
<tr><td>Email:</td><td>				<input type="text" name="email" value="" /></td></tr>
<tr><td>Date:</td><td>				<input type="text" name="date" value="#DateFormat(Now())# - #TimeFormat(Now())#" /></td></tr>
<tr><td valign="top">Memo:</td><td>	<textarea name="memo" cols="40" rows="10"></textarea></td></tr>
</table></p>

<small>Note: The name attributes are hard coded in order to produce this form, but they could be anything.<br />
Also, this form does not take advantage of the fact that each name attribute can have multiple values.</small>

<br />
<br />
<input type="submit" name="submit" value="Submit" /> <input type="reset" />
</cfform>
</cfif>

<br /><a href="#cgi.SCRIPT_NAME#">Refresh</a>
</cfoutput>

<cfcatch type="Any"><cfinclude template="error.cfm"></cfcatch>
</div>
</div>
</body></html></cftry>