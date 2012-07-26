<table border="0" cellspacing="0" cellpadding="10" width="80%"><tr><td>

<cfoutput>
<h2><font color="red">#cfcatch.message#</font></h2>
<h3>#cfcatch.detail#</h3>

<!---<cfdump var="#CFCATCH.TAGCONTEXT#">--->

<cfloop index = i from = 1 to = #ArrayLen(CFCATCH.TAGCONTEXT)#>
	<cfset sCurrent = #CFCATCH.TAGCONTEXT[i]#>
    Line: #sCurrent["LINE"]#<br />
    Template: #sCurrent["TEMPLATE"]#<br />
</cfloop>

<br />

<form action="#cgi.script_name#">
<input type="submit" value="OK" />
</form>

</cfoutput>

</td></tr></table>
