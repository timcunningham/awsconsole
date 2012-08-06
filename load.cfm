<cfset tick = gettickCount()>

<cfloop from=1 to=10000 index="i">
	
	<cfoutput>ec2_#i#<br></cfoutput>
	<cfflush>
	<cfset tick1 = gettickCount()>
	
	<cfset "ec2_#i#" = createObject("component","cfcs.ec2").init("#i#","#i#")>
	<cfset tock2 =  gettickCount()>
	<cfoutput>#tock2-tick2# <br></cfoutput>
</cfloop>
<cfset tock =  gettickCount()>
<cfoutput>overall #tock-tick# ms</cfoutput>