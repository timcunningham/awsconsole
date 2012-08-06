<cfset tick = gettickCount()>

<cfloop from=1 to=10000 index="i">
	<cfset "ec2_#i#" = createObject("component","cfcs.ec2").init("#i#","#i#")>
</cfloop>
<cfset tock =  gettickCount()>
<cfoutput>overall #tock-tick# ms</cfoutput>