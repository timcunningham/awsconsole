<cfloop from=1 to=100 index="i">
	<cfset "#createUUID()#" = createObject("component","cfcs.ec2").init(accessKeyId,secretAccessKey)>
</cfloop>