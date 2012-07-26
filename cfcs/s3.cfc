<cfcomponent output="false">

<!---
Amazon S3 REST Wrapper

Written by Joe Danziger (joe@ajaxcf.com) with much help from
dorioo on the Amazon S3 Forums.  See the readme for more
details on usage and methods.
Thanks to Steve Hicks for the bucket ACL updates.
Thanks to for the EU storage location updates.

Version 1.3 - Released: November 28, 2007
Updated by David Smith, March 2008: putObject now uses POST instead of GET. 
--->

	<cffunction name="init" access="public" output="false" returnType="s3" hint="Returns an instance of the CFC initialized.">
		<cfargument name="accessKeyId" type="string" required="true" hint="Amazon S3 Access Key ID.">
		<cfargument name="secretAccessKey" type="string" required="true" hint="Amazon S3 Secret Access Key.">
		
		<cfset variables.accessKeyId = arguments.accessKeyId>
		<cfset variables.secretAccessKey = arguments.secretAccessKey>
	
		<cfreturn this>
	</cffunction>
	
	<cffunction name="hexToBin" output="false" access="private">
		<cfargument name="inputString" type="string" required="true" hint="The hexadecimal string to be written.">
	
		<cfset var outStream = CreateObject("java", "java.io.ByteArrayOutputStream").init()>
		<cfset var inputLength = Len(arguments.inputString)>
		<cfset var outputString = "">
		<cfset var i = 0>
		<cfset var ch = "">
	
		<cfif inputLength mod 2 neq 0>
			<cfset arguments.inputString = "0" & inputString>
		</cfif>
	
		<cfloop from="1" to="#inputLength#" index="i" step="2">
			<cfset ch = Mid(inputString, i, 2)>
			<cfset outStream.write(javacast("int", InputBaseN(ch, 16)))>
		</cfloop>
	
		<cfset outStream.flush()>
		<cfset outStream.close()>
	
		<cfreturn outStream.toByteArray()>
	</cffunction>


	<cffunction name="createSignature" output="false" returntype="string">
		<cfargument name="fixedData" type="string" required="true"/>
		
		<cfinvoke component="HMAC" method="hmac" returnvariable="Function.digest">
			<cfinvokeargument name="hash_function" value="sha1"/>
			<cfinvokeargument name="data" value="#Arguments.fixedData#"/>
			<cfinvokeargument name="key" value="#variables.secretAccessKey#"/>
		</cfinvoke>

        <cfreturn ToBase64(hexToBin(Function.digest))/>
	</cffunction>

	<cffunction name="getBuckets" access="public" output="false" returntype="array" 
				description="List all available buckets.">
		
		<cfset var signature = "">
		<cfset var data = "">
		<cfset var bucket = "">
		<cfset var buckets = "">
		<cfset var thisBucket = "">
		<cfset var allBuckets = "">
		<cfset var dateTimeString = GetHTTPTimeString(Now())>
		
		<!--- Create a canonical string to send --->
		<cfset var cs = "GET\n\n\n#dateTimeString#\n/">
		
		<!--- Replace "\n" with "chr(10) to get a correct digest --->
		<cfset var fixedData = replace(cs,"\n","#chr(10)#","all")>

		<!--- Calculate signature --->
		<cfset signature = createSignature(fixedData)/>
		
		<!--- get all buckets via REST --->
		<cfhttp method="GET" url="http://s3.amazonaws.com">
			<cfhttpparam type="header" name="Date" value="#dateTimeString#">
			<cfhttpparam type="header" name="Authorization" value="AWS #variables.accessKeyId#:#signature#">
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
		
			<cfset data = xmlParse(cfhttp.FileContent)>
			<cfset buckets = xmlSearch(data, "//:Bucket")>
	
			<!--- create array and insert values from XML --->
			<cfset allBuckets = arrayNew(1)>
			<cfloop index="x" from="1" to="#arrayLen(buckets)#">
			   <cfset bucket = buckets[x]>
			   <cfset thisBucket = structNew()>
			   <cfset thisBucket.Name = bucket.Name.xmlText>
			   <cfset thisBucket.CreationDate = bucket.CreationDate.xmlText>
			   <cfset arrayAppend(allBuckets, thisBucket)>   
			</cfloop>
			
			<cfreturn allBuckets>
		</cfif>		
	</cffunction>
	
	<cffunction name="handleErrors" output="true" returntype="void" access="private">
		<cfargument name="content" type="string" required="true"/>

		<cfset var Local = StructNew()/>
		
		<cfif Arguments.content is "Connection failure">	
			<cfthrow type="ConnectionFailureException" 
				message="Connection failure." 
				detail="No connection could be made to ""#Arguments.uri#""."
			/>
		<cfelse>
			<!--- Get first error --->
		
			<cfset Local.content = XmlSearch(Arguments.content, "//Error")/>
	
			<cfset Local.errorCode = Local.content[1].Code.XmlText/>
			<cfset Local.errorMessage = Local.content[1].Message.XmlText/>
			
			<!--- Create CF exception from error --->
			
			<cfthrow type="#Local.errorCode#" 
				message="#Local.errorCode#" 
				detail="#Local.errorMessage#"
			/>
		</cfif>
	</cffunction>
	
	<cffunction name="putBucket" access="public" output="false" returntype="boolean" 
				description="Creates a bucket.">
		<cfargument name="bucketName" type="string" required="true">
		<cfargument name="acl" type="string" required="false" default="public-read">
		<cfargument name="storageLocation" type="string" required="false" default="">
		
		<cfset var signature = "">
		<cfset var dateTimeString = GetHTTPTimeString(Now())>

		<!--- Create a canonical string to send based on operation requested ---> 
		<cfset var cs = "PUT\n\ntext/html\n#dateTimeString#\nx-amz-acl:#arguments.acl#\n/#arguments.bucketName#">

		<!--- Replace "\n" with "chr(10) to get a correct digest --->
		<cfset var fixedData = replace(cs,"\n","#chr(10)#","all")> 

		<!--- Calculate signature --->
		<cfset signature = createSignature(fixedData)/>

		<cfif arguments.storageLocation eq "EU">
			<cfsavecontent variable="strXML">
				<CreateBucketConfiguration><LocationConstraint>EU</LocationConstraint></CreateBucketConfiguration>
			</cfsavecontent>
		<cfelse>
			<cfset strXML = "">
		</cfif>

		<!--- put the bucket via REST --->
		<cfhttp method="PUT" url="http://s3.amazonaws.com/#arguments.bucketName#" charset="utf-8">
			<cfhttpparam type="header" name="Content-Type" value="text/html">
			<cfhttpparam type="header" name="Date" value="#dateTimeString#">
			<cfhttpparam type="header" name="x-amz-acl" value="#arguments.acl#">
			<cfhttpparam type="header" name="Authorization" value="AWS #variables.accessKeyId#:#signature#">
			<cfhttpparam type="body" value="#trim(variables.strXML)#">
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
		
			<cfreturn true>
		
		</cfif>
	</cffunction>
	
	<cffunction name="getBucket" access="public" output="false" returntype="array" 
				description="Creates a bucket.">
		<cfargument name="bucketName" type="string" required="yes">
		<cfargument name="prefix" type="string" required="false" default="">
		<cfargument name="marker" type="string" required="false" default="">
		<cfargument name="maxKeys" type="string" required="false" default="">
		
		<cfset var signature = "">
		<cfset var data = "">
		<cfset var content = "">
		<cfset var contents = "">
		<cfset var thisContent = "">
		<cfset var allContents = "">
		<cfset var dateTimeString = GetHTTPTimeString(Now())>

		<!--- Create a canonical string to send --->
		<cfset var cs = "GET\n\n\n#dateTimeString#\n/#arguments.bucketName#">

		<!--- Replace "\n" with "chr(10) to get a correct digest --->
		<cfset var fixedData = replace(cs,"\n","#chr(10)#","all")>

		<!--- Calculate signature --->
		<cfset signature = createSignature(fixedData)/>

		<!--- get the bucket via REST --->
		<cfhttp method="GET" url="http://s3.amazonaws.com/#arguments.bucketName#">
			<cfhttpparam type="header" name="Date" value="#dateTimeString#">
			<cfhttpparam type="header" name="Authorization" value="AWS #variables.accessKeyId#:#signature#">
			<cfif compare(arguments.prefix,'')>
				<cfhttpparam type="URL" name="prefix" value="#arguments.prefix#"> 
			</cfif>
			<cfif compare(arguments.marker,'')>
				<cfhttpparam type="URL" name="marker" value="#arguments.marker#"> 
			</cfif>
			<cfif isNumeric(arguments.maxKeys)>
				<cfhttpparam type="URL" name="max-keys" value="#arguments.maxKeys#"> 
			</cfif>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
		
			<cfset data = xmlParse(cfhttp.FileContent)>
			<cfset contents = xmlSearch(data, "//:Contents")>
	
			<!--- create array and insert values from XML --->
			<cfset allContents = arrayNew(1)>
			<cfloop index="x" from="1" to="#arrayLen(contents)#">
				<cfset content = contents[x]>
				<cfset thisContent = structNew()>
				<cfset thisContent.Key = content.Key.xmlText>
				<cfset thisContent.LastModified = content.LastModified.xmlText>
				<cfset thisContent.Size = content.Size.xmlText>
				<cfset arrayAppend(allContents, thisContent)>   
			</cfloop>

			<cfreturn allContents>
		</cfif>
	</cffunction>
	
	<cffunction name="deleteBucket" access="public" output="false" returntype="boolean" 
				description="Deletes a bucket.">
		<cfargument name="bucketName" type="string" required="yes">	
		
		<cfset var signature = "">
		<cfset var dateTimeString = GetHTTPTimeString(Now())>
		
		<!--- Create a canonical string to send based on operation requested ---> 
		<cfset var cs = "DELETE\n\n\n#dateTimeString#\n/#arguments.bucketName#"> 
		
		<!--- Replace "\n" with "chr(10) to get a correct digest --->
		<cfset var fixedData = replace(cs,"\n","#chr(10)#","all")> 
		
		<!--- Calculate signature --->
		<cfset signature = createSignature(fixedData)/>
		
		<!--- delete the bucket via REST --->
		<cfhttp method="DELETE" url="http://s3.amazonaws.com/#arguments.bucketName#" charset="utf-8">
			<cfhttpparam type="header" name="Date" value="#dateTimeString#">
			<cfhttpparam type="header" name="Authorization" value="AWS #variables.accessKeyId#:#signature#">
		</cfhttp>
		
		<cfreturn true>
	</cffunction>
	
	<!--- The original S3CFC (http://amazons3.riaforge.org)/ uses GET intead of POST to send files, but POST is better since files don't have to be read into memory --->
    <cffunction name="putObject" access="public" output="true" returntype="string">
		<cfargument name="bucketName" type="string" required="yes">
		<cfargument name="fileKey" type="string" required="yes">
		<cfargument name="contentType" type="string" required="no">
		<cfargument name="HTTPtimeout" type="numeric" required="no" default="300">
        
        <cfsavecontent variable="policyArgs">
        {
		  "expiration": "2009-01-01T12:00:00.000Z",
		  "conditions": [
		    {"key": "#GetFileFromPath(arguments.fileKey)#" },
		    {"bucket": "#arguments.bucketName#" },
            {"success_action_status": "201" },
		  ]
		}
        </cfsavecontent>

		<cfset policy = ToBase64(policyArgs)>
        <cfset signature = createSignature(policy)>
        
		<cfhttp method="POST" url="http://s3.amazonaws.com/#arguments.bucketName#" timeout="#arguments.HTTPtimeout#">
			  <cfhttpparam type="formfield" name="policy" value="#policy#">
			  <cfhttpparam type="formfield" name="AWSAccessKeyId" value="#variables.accessKeyId#">
			  <cfhttpparam type="formfield" name="signature" value="#signature#">
			  <cfhttpparam type="formfield" name="key" value="#GetFileFromPath(arguments.fileKey)#">
              <cfhttpparam type="formfield" name="success_action_status" value="201">
			  <cfhttpparam type="file" name="file" file="#ExpandPath("./#arguments.fileKey#")#">
		</cfhttp> 
        
	   <cfif CFHTTP.ResponseHeader.Status_Code neq 201>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>			
			<cfreturn XmlParse(CFHTTP.FileContent).PostResponse.Etag/>
    	</cfif>
	</cffunction>

	<cffunction name="getObject" access="public" output="false" returntype="string" 
				description="Returns a link to an object.">
		<cfargument name="bucketName" type="string" required="yes">
		<cfargument name="fileKey" type="string" required="yes">
		<cfargument name="minutesValid" type="string" required="false" default="60">
		
		<cfset var signature = "">
		<cfset var timedAmazonLink = "">
		<cfset var epochTime = DateDiff("s", DateConvert("utc2Local", "January 1 1970 00:00"), now()) + (arguments.minutesValid * 60)>

		<!--- Create a canonical string to send --->
		<cfset var cs = "GET\n\n\n#epochTime#\n/#arguments.bucketName#/#arguments.fileKey#">

		<!--- Replace "\n" with "chr(10) to get a correct digest --->
		<cfset var fixedData = replace(cs,"\n","#chr(10)#","all")>

		<!--- Calculate signature --->
		<cfset signature = createSignature(fixedData)/>

		<!--- Create the timed link for the image --->
		<cfset timedAmazonLink = "http://s3.amazonaws.com/#arguments.bucketName#/#arguments.fileKey#?AWSAccessKeyId=#variables.accessKeyId#&Expires=#epochTime#&Signature=#signature#">

		<cfreturn timedAmazonLink>
	</cffunction>

	<cffunction name="deleteObject" access="public" output="false" returntype="boolean" 
				description="Deletes an object.">
		<cfargument name="bucketName" type="string" required="yes">
		<cfargument name="fileKey" type="string" required="yes">

		<cfset var signature = "">
		<cfset var dateTimeString = GetHTTPTimeString(Now())>

		<!--- Create a canonical string to send based on operation requested ---> 
		<cfset var cs = "DELETE\n\n\n#dateTimeString#\n/#arguments.bucketName#/#arguments.fileKey#"> 

		<!--- Replace "\n" with "chr(10) to get a correct digest --->
		<cfset var fixedData = replace(cs,"\n","#chr(10)#","all")> 

		<!--- Calculate signature --->
		<cfset signature = createSignature(fixedData)/>
        
		<!--- delete the object via REST --->
		<cfhttp method="DELETE" url="http://s3.amazonaws.com/#arguments.bucketName#/#arguments.fileKey#">
			<cfhttpparam type="header" name="Date" value="#dateTimeString#">
			<cfhttpparam type="header" name="Authorization" value="AWS #variables.accessKeyId#:#signature#">
		</cfhttp>

		<cfreturn true>
	</cffunction>

</cfcomponent>