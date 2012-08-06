<cfloop from=1 to=100 index="i">
	<cfset "ec2_#i#" = createObject("component","cfcs.ec2").init("","")>
</cfloop>