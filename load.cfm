<cfset tick = gettickCount()>

<cfloop from=1 to=1000 index="i">

	<cfset "ec2_#i#" = createObject("component","cfcs.ec2").init("#i#","#i#")>
</cfloop>
<cfset tock =  gettickCount()>
<cfoutput>#tock-tick#</cfoutput>