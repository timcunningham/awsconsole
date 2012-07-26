<cfcomponent output="false">

<!---

Amazon EC2 CFC

Copyright (c) 2007-2008, Jeffrey Pratt

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
	* Neither the name of Simplicity Group, LLC nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

--->

	<cfset Variables.ec2Version = "2007-08-29"/>
	<cfset Variables.serviceUrl = "https://ec2.amazonaws.com/"/>

	<cffunction name="init" output="false" returntype="EC2" hint="Returns an instance of the CFC initialized.">
		<cfargument name="awsAccessKeyId" type="string" required="true"/>
		<cfargument name="secretAccessKey" type="string" required="true"/>
		
		<cfset Variables.awsAccessKeyId = Arguments.awsAccessKeyId/>
		<cfset Variables.secretAccessKey = Arguments.secretAccessKey/>
		
		<cfreturn This/>
	</cffunction>

	<cffunction name="authorizeSecurityGroupIngress" output="false" returntype="boolean">
		<cfargument name="groupName" type="string" required="true"/>
		<cfargument name="sourceSecurityGroupName" type="string" required="false" hint="Required when authorizing user/group pair permission"/>
		<cfargument name="sourceSecurityGroupOwnerId" type="string" required="false" hint="Required when authorizing user/group pair permission"/>
		<cfargument name="ipProtocol" type="string" required="false" hint="Required when authorizing CIDR IP permission; valid values are (tcp|udp|icmp)"/>
		<cfargument name="fromPort" type="numeric" required="false" hint="Required when authorizing CIDR IP permission"/>
		<cfargument name="toPort" type="numeric" required="false" hint="Required when authorizing CIDR IP permission"/>
		<cfargument name="cidrIp" type="string" required="false" hint="Required when authorizing CIDR IP permission"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfif IsDefined("Arguments.sourceSecurityGroupName")>
			<cfset Local.sourceSecurityGroupNamePair = "SourceSecurityGroupName#Arguments.sourceSecurityGroupName#"/>
		<cfelse>
			<cfset Local.sourceSecurityGroupNamePair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.sourceSecurityGroupOwnerId")>
			<cfset Local.sourceSecurityGroupOwnerIdPair = "SourceSecurityGroupOwnerId#Arguments.sourceSecurityGroupOwnerId#"/>
		<cfelse>
			<cfset Local.sourceSecurityGroupOwnerIdPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.ipProtocol")>
			<cfset Local.ipProtocolPair = "IpProtocol#Arguments.ipProtocol#"/>
		<cfelse>
			<cfset Local.ipProtocolPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.fromPort")>
			<cfset Local.fromPortPair = "FromPort#Arguments.fromPort#"/>
		<cfelse>
			<cfset Local.fromPortPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.toPort")>
			<cfset Local.toPortPair = "ToPort#Arguments.toPort#"/>
		<cfelse>
			<cfset Local.toPortPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.cidrIp")>
			<cfset Local.cidrIpPair = "CidrIp#Arguments.cidrIp#"/>
		<cfelse>
			<cfset Local.cidrIpPair = ""/>
		</cfif>
		
		<cfset Local.fixedData = "ActionAuthorizeSecurityGroupIngress" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 Local.cidrIpPair &
								 Local.fromPortPair &
								 "GroupName#Arguments.groupName#" &
								 Local.ipProtocolPair &
								 "SignatureVersion1" &
								 Local.sourceSecurityGroupNamePair &
								 Local.sourceSecurityGroupOwnerIdPair &
								 "Timestamp#Local.dateTimeString#" &
								 Local.toPortPair &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="AuthorizeSecurityGroupIngress"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfif IsDefined("Arguments.cidrIp")>
				<cfhttpparam type="url" name="CidrIp" value="#Arguments.cidrIp#"/>
			</cfif>
			<cfif IsDefined("Arguments.fromPort")>
				<cfhttpparam type="url" name="FromPort" value="#Arguments.fromPort#"/>
			</cfif>
			<cfhttpparam type="url" name="GroupName" value="#Arguments.groupName#"/>
			<cfif IsDefined("Arguments.ipProtocol")>
				<cfhttpparam type="url" name="IpProtocol" value="#Arguments.ipProtocol#"/>
			</cfif>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfif IsDefined("Arguments.sourceSecurityGroupName")>
				<cfhttpparam type="url" name="SourceSecurityGroupName" value="#Arguments.sourceSecurityGroupName#"/>
			</cfif>
			<cfif IsDefined("Arguments.sourceSecurityGroupOwnerId")>
				<cfhttpparam type="url" name="SourceSecurityGroupOwnerId" value="#Arguments.sourceSecurityGroupOwnerId#"/>
			</cfif>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfif IsDefined("Arguments.toPort")>
				<cfhttpparam type="url" name="ToPort" value="#Arguments.toPort#"/>
			</cfif>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).AuthorizeSecurityGroupIngressResponse.return.XmlText/>
		</cfif>
	</cffunction>
	
	<cffunction name="confirmProductInstance" output="false" returntype="struct">
		<cfargument name="productCode" type="string" required="true"/>
		<cfargument name="instanceId" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionConfirmProductInstance" & 
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" & 
								 "InstanceId#Arguments.instanceId#" &
								 "ProductCode#Arguments.productCode#" & 
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
								 
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="ConfirmProductInstance"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="InstanceId" value="#Arguments.instanceId#"/>
			<cfhttpparam type="url" name="ProductCode" value="#Arguments.productCode#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfset Local.confirmProductInstanceResponse = XmlParse(CFHTTP.FileContent).ConfirmProductInstanceResponse/>
		
			<cfset Local.response = StructNew()/>
			
			<cfset Local.response.result = Local.confirmProductInstanceResponse.result.XmlText/>
			<cfset Local.response.ownerId = Local.confirmProductInstanceResponse.ownerId.XmlText/>
			
			<cfreturn Local.response/>
		</cfif>
	</cffunction>
	
	<cffunction name="createKeyPair" output="false" returntype="struct">
		<cfargument name="keyName" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionCreateKeyPair" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "KeyName#Arguments.keyName#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="CreateKeyPair"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="KeyName" value="#Arguments.keyName#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfset Local.createKeyPairResponse = XmlParse(CFHTTP.FileContent).CreateKeyPairResponse/>
		
			<cfset Local.response = StructNew()/>
			
			<cfset Local.response.keyName = Local.createKeyPairResponse.keyName.XmlText/>
			<cfset Local.response.keyFingerprint = Local.createKeyPairResponse.keyFingerprint.XmlText/>
			<cfset Local.response.keyMaterial = Local.createKeyPairResponse.keyMaterial.XmlText/>
			
			<cfreturn Local.response/>
		</cfif>
	</cffunction>

	<cffunction name="createSecurityGroup" output="false" returntype="boolean">
		<cfargument name="groupName" type="string" required="true"/>
		<cfargument name="groupDescription" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionCreateSecurityGroup" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "GroupDescription#Arguments.groupDescription#" &
								 "GroupName#Arguments.groupName#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="CreateSecurityGroup"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="GroupDescription" value="#Arguments.groupDescription#"/>
			<cfhttpparam type="url" name="GroupName" value="#Arguments.groupName#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).CreateSecurityGroupResponse.return.XmlText/>
		</cfif>
	</cffunction>
	
	<cffunction name="createSignature" output="false" returntype="string" access="private">
		<cfargument name="fixedData" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<!--- Hash signature string --->
											
		<cfinvoke component="HMAC" method="hmac" returnvariable="Local.digest">
			<cfinvokeargument name="hash_function" value="sha1"/>
			<cfinvokeargument name="data" value="#Arguments.fixedData#"/>
			<cfinvokeargument name="key" value="#Variables.secretAccessKey#"/>
		</cfinvoke>
		
		<!--- Create signature --->
		
		<cfreturn ToBase64(hexToBin(Local.digest))/>
	</cffunction>

	<cffunction name="deleteKeyPair" output="false" returntype="boolean">
		<cfargument name="keyName" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionDeleteKeyPair" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "KeyName#Arguments.keyName#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>

		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="DeleteKeyPair"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="KeyName" value="#Arguments.keyName#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).DeleteKeyPairResponse.return.XmlText/>
		</cfif>
	</cffunction>

	<cffunction name="deleteSecurityGroup" output="false" returntype="boolean">
		<cfargument name="groupName" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionDeleteSecurityGroup" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "GroupName#Arguments.groupName#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="DeleteSecurityGroup"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="GroupName" value="#Arguments.groupName#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).DeleteSecurityGroupResponse.return.XmlText/>
		</cfif>
	</cffunction>
	
	<cffunction name="deregisterImage" output="false" returntype="boolean">
		<cfargument name="imageId" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionDeregisterImage" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "ImageId#Arguments.imageId#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="DeregisterImage"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="ImageId" value="#Arguments.imageId#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).DeregisterImageResponse.return.XmlText/>
		</cfif>
	</cffunction>
	
	<cffunction name="describeImageAttribute" output="false" returntype="struct">
		<cfargument name="imageId" type="string" required="true"/>
		<cfargument name="attribute" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionDescribeImageAttribute" &
		                         "Attribute#Arguments.attribute#" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "ImageId#Arguments.imageId#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="DescribeImageAttribute"/>
			<cfhttpparam type="url" name="Attribute" value="#Arguments.attribute#"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="ImageId" value="#Arguments.imageId#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfset Local.describeImageAttributesResponse = XmlParse(CFHTTP.FileContent).DescribeImageAttributesResponse/>
		
			<cfset Local.response = StructNew()/>
			<cfset Local.response.imageId = Local.describeImageAttributesResponse.imageId.XmlText/>
		
			<cfif Arguments.attribute is "launchPermission">
				<cfset Local.launchPermissions = Local.describeImageAttributesResponse.launchPermission.item/>
				
				<cfset Local.response.launchPermissions = ArrayNew(1)/>
				
				<cfloop index="Local.i" from="1" to="#ArrayLen(Local.launchPermissions)#">
					<cfset Local.item = Local.launchPermissions[Local.i].item/>
					<cfif IsDefined("Local.item.group")>
						<cfset Local.response.launchPermissions[Local.i].type = "group"/>
						<cfset Local.response.launchPermissions[Local.i].value = Local.item.group.XmlText/>
					<cfelse>
						<cfset Local.response.launchPermissions[Local.i].type = "userId"/>
						<cfset Local.response.launchPermissions[Local.i].value = Local.item.userId.XmlText/>
					</cfif>
				</cfloop>
			<cfelseif Arguments.attribute is "productCodes">
				<cfset Local.productCodes = Local.describeImageAttributesResponse.productCodes.item/>
				
				<cfloop index="Local.i" from="1" to="#ArrayLen(Local.productCodes)#">
					<cfset Local.response.productCodes[Local.i] = Local.productCodes[Local.i].XmlText/>
				</cfloop>
			</cfif>
			
			<cfreturn Local.response/>
		</cfif>
	</cffunction>
	
	<cffunction name="describeImages" output="true" returntype="array">
		<cfargument name="ownerList" type="string" required="false" hint="List of AMI owners"/>
		<cfargument name="imageIdList" type="string" required="false" hint="List of image descriptions"/>
		<cfargument name="executableByList" type="string" required="false" hint="List of AMIs for which specified users have access"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.imageIdListPairs = ""/>
		<cfset Local.index = 1/>
		
		<cfif IsDefined("Arguments.imageIdList")>
			<cfloop list="#Arguments.imageIdList#" index="Local.imageId">
				<cfset Local.imageIdListPairs = Local.imageIdListPairs & "ImageId.#Local.index##Local.imageId#"/>
			</cfloop>
		</cfif>
		
		<cfset Local.ownerListPairs = ""/>
		<cfset Local.index = 1/>
		
		<cfif IsDefined("Arguments.ownerList")>
			<cfloop list="#Arguments.ownerList#" index="Local.owner">
				<cfset Local.ownerListPairs = Local.ownerListPairs & "Owner.#Local.index##Local.owner#"/>
			</cfloop>
		</cfif>
		
		<cfset Local.executableByListPairs = ""/>
		<cfset Local.index = 1/>
		
		<cfif IsDefined("Arguments.executableByList")>
			<cfloop list="#Arguments.executableByList#" index="Local.executableBy">
				<cfset Local.executableByListPairs = Local.executableByListPairs & "ExecutableBy.#Local.index##Local.executableBy#"/>
			</cfloop>
		</cfif>
		
		<cfset Local.fixedData = "ActionDescribeImages" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 Local.executableByListPairs &
								 Local.imageIdListPairs &
								 Local.ownerListPairs &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
        
        		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="DescribeImages"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfif IsDefined("Arguments.executableByList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.executableByList#" index="Local.executableBy">
					<cfhttpparam type="url" name="ExecutableBy.#Local.index#" value="#Local.executableBy#"/>
				</cfloop>
			</cfif>
			<cfif IsDefined("Arguments.imageIdList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.imageIdList#" index="Local.imageId">
					<cfhttpparam type="url" name="ImageId.#Local.index#" value="#Local.imageId#"/>
				</cfloop>
			</cfif>
			<cfif IsDefined("Arguments.ownerList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.ownerList#" index="Local.owner">
					<cfhttpparam type="url" name="Owner.#Local.index#" value="#Local.owner#"/>
				</cfloop>
			</cfif>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			
			<cfset Local.response = ArrayNew(1)/>
			
            <cftry> <!--- This cftry/cfcatch is to bypass user accounts with no AMIs defined yet --->
			<cfset Local.imagesSet = XmlParse(CFHTTP.FileContent).DescribeImagesResponse.imagesSet.item/>
			
			<cfloop index="Local.i" from="1" to="#ArrayLen(Local.imagesSet)#">
				<cfset Local.response[Local.i] = StructNew()/>
				<cfset Local.response[Local.i].imageid = Local.imagesSet[Local.i].imageId.XmlText/>
				<cfset Local.response[Local.i].imageLocation = Local.imagesSet[Local.i].imageLocation.XmlText/>
				<cfset Local.response[Local.i].imageState = Local.imagesSet[Local.i].imageState.XmlText/>
				<cfset Local.response[Local.i].imageOwnerId = Local.imagesSet[Local.i].imageOwnerId.XmlText/>
				<cfset Local.response[Local.i].isPublic = Local.imagesSet[Local.i].isPublic.XmlText/>
				<cfset Local.response[Local.i].productCodes = ArrayNew(1)/>
				<cfset Local.imagesSetCurrent = Local.imagesSet[Local.i]/>
				<cfif IsDefined("Local.imagesSetCurrent.productCodes.item")>
					<cfset Local.productCodes = Local.imagesSet[Local.i].productCodes.item/>
					<cfloop index="Local.j" from="1" to="#ArrayLen(Local.productCodes)#">
						<cfset Local.response[Local.i].productCodes[Local.j] = Local.productCodes[Local.j].productCode.XmlText/>
					</cfloop>
				</cfif>
			</cfloop>
			<cfcatch></cfcatch></cftry>
            
			<cfreturn Local.response/>
		</cfif>
	</cffunction>
	
	<cffunction name="describeInstances" output="false" returntype="array">
		<cfargument name="instanceIdList" type="string" required="false" hint="List of instance IDs"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.instanceIdListPairs = ""/>
		<cfset Local.index = 1/>
		
		<cfif IsDefined("Arguments.instanceIdList")>
			<cfloop list="#Arguments.instanceIdList#" index="Local.instanceId">
				<cfset Local.instanceIdListPairs = Local.instanceIdListPairs & "InstanceId.#Local.index##Local.instanceId#"/>
			</cfloop>
		</cfif>
		
		<cfset Local.fixedData = "ActionDescribeInstances" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
		                         Local.instanceIdListPairs &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="DescribeInstances"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfif IsDefined("Arguments.instanceIdList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.instanceIdList#" index="Local.instanceId">
					<cfhttpparam type="url" name="InstanceId.#Local.index#" value="#Local.instanceId#"/>
				</cfloop>
			</cfif>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<!--- Added cftry/cfcatch around reservationSet to catch when NO instances are running --->
			<cftry>
				<cfset Local.reservationSet = XmlParse(CFHTTP.FileContent).DescribeInstancesResponse.ReservationSet.item/>
				<cfcatch><cfset Local.reservationSet = "#ArrayNew(1)#"></cfcatch>
			</cftry>
						
			<cfset Local.response = ArrayNew(1)/>			
			
			<cfloop index="Local.i" from="1" to="#ArrayLen(Local.reservationSet)#">
				<cfset Local.response[Local.i] = StructNew()/>
				<cfset Local.response[Local.i].reservationId = Local.reservationSet[Local.i].reservationId.XmlText/>
				<cfset Local.response[Local.i].ownerId = Local.reservationSet[Local.i].ownerId.XmlText/>
				<cfset Local.response[Local.i].groupSet = ArrayNew(1)/>
				<cfloop index="Local.j" from="1" to="#ArrayLen(Local.reservationSet[Local.i].groupSet.item)#">
					<cfset Local.response[Local.i].groupSet[Local.j] = Local.reservationSet[Local.i].groupSet.item[Local.j].groupId.XmlText/>
				</cfloop>
				<cfset Local.response[Local.i].instancesSet = ArrayNew(1)/>
				<cfset Local.instancesSet = Local.reservationSet[Local.i].instancesSet.item/>
				<cfloop index="Local.k" from="1" to="#ArrayLen(Local.instancesSet)#">
					<cfset Local.response[Local.i].instancesSet[Local.k] = StructNew()/>
					<cfset Local.response[Local.i].instancesSet[Local.k].instanceId = Local.instancesSet[Local.k].instanceId.XmlText/>
					<cfset Local.response[Local.i].instancesSet[Local.k].imageId = Local.instancesSet[Local.k].imageId.Xmltext/>
					<cfset Local.response[Local.i].instancesSet[Local.k].instanceState = StructNew()/>
					<cfset Local.response[Local.i].instancesSet[Local.k].instanceState.code = Local.instancesSet[Local.k].instanceState.code.XmlText/>
					<cfset Local.response[Local.i].instancesSet[Local.k].instanceState.name = Local.instancesSet[Local.k].instanceState.name.XmlText/>
					<cfset Local.response[Local.i].instancesSet[Local.k].privateDnsName = Local.instancesSet[Local.k].privateDnsName.XmlText/>
					<cfset Local.response[Local.i].instancesSet[Local.k].dnsName = Local.instancesSet[Local.k].dnsName.XmlText/>
					<!--- Added cftry/cfcatch around keyName variable incase an instance is started without a key-pair --->
					<cftry>
						<cfset Local.response[Local.i].instancesSet[Local.k].keyName = #Local.instancesSet[Local.k].keyName.XmlText#/>
						<cfcatch><cfset Local.response[Local.i].instancesSet[Local.k].keyName = "[none]"></cfcatch>
					</cftry>
					<cfset Local.response[Local.i].instancesSet[Local.k].productCodesSet = ArrayNew(1)/>
					<cfset Local.instancesSetCurrent = Local.reservationSet[Local.i].instancesSet.item[Local.k]/>
					<cfif IsDefined("Local.instancesSetCurrent.productCodesSet.item")>
						<cfset Local.productCodesSet = Local.reservationSet[Local.i].instancesSet.item[Local.k].productCodesSet.item/>
						<cfloop index="Local.m" from="1" to="#ArrayLen(Local.productCodesSet)#">
							<cfset Local.response[Local.i].instancesSet[Local.k].productCodesSet[Local.m] = Local.productCodesSet[Local.m].productCode.Xmltext/>
						</cfloop>
					</cfif>
					<cfset Local.response[Local.i].instancesSet[Local.k].instanceType = Local.instancesSet[Local.k].instanceType.XmlText/>
					<cfset Local.response[Local.i].instancesSet[Local.k].launchTime = Local.instancesSet[Local.k].launchTime.XmlText/>
				</cfloop>
			</cfloop>
			
			<cfreturn Local.response/>
		</cfif>
	</cffunction>
	
	<cffunction name="describeKeyPairs" output="false" returntype="array">
		<cfargument name="keyNameList" type="string" required="false" hint="List of key pair IDs"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.keyNameListPairs = ""/>
	
		<cfif IsDefined("Arguments.keyNameList")>
			<cfset Local.index = 1/>
			
			<cfloop list="#Arguments.keyNameList#" index="Local.keyName">
				<cfset Local.keyNameListPairs = Local.keyNameListPairs & "KeyName.#Local.index##Local.keyName#"/>
				<cfset Local.index = Local.index + 1/>
			</cfloop>
		</cfif>
		
		<cfset Local.fixedData = "ActionDescribeKeyPairs" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 Local.keyNameListPairs &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="DescribeKeyPairs"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfif IsDefined("Arguments.keyNameList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.keyNameList#" index="Local.keyName">
					<cfhttpparam type="url" name="KeyName.#Local.index#" value="#Local.keyName#"/>
					<cfset Local.index = Local.index + 1/>
				</cfloop>
			</cfif>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			
			<cfset Local.response = ArrayNew(1)/>
			<cftry> <!--- Added cftry/cfcatch to bypass user accounts with no keypairs --->
			<cfset Local.keySet = XmlParse(CFHTTP.FileContent).DescribeKeyPairsResponse.keySet.item/>

			<cfloop index="Local.i" from="1" to="#ArrayLen(Local.keySet)#">
				<cfset Local.response[Local.i] = StructNew()/>
				<cfset Local.response[Local.i].keyName = Local.keySet[Local.i].keyName.XmlText/>
				<cfset Local.response[Local.i].keyFingerprint = Local.keySet[Local.i].keyFingerprint.XmlText/>
			</cfloop>
			<cfcatch></cfcatch></cftry>
            
			<cfreturn Local.response/>
		</cfif>
	</cffunction>

	<cffunction name="describeSecurityGroups" output="false" returntype="array">
		<cfargument name="groupNameList" type="string" required="false" hint="List of security group names"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.groupNameListPairs = ""/>
		
		<cfif IsDefined("Arguments.groupNameList")>
			<cfset Local.index = 1/>
			<cfloop list="#Arguments.groupNameList#" index="Local.groupName">
				<cfset Local.groupNameListPairs = Local.groupNameListPairs & "GroupName.#Local.index##Local.groupName#"/>
				<cfset Local.index = Local.index + 1/>
			</cfloop>
		</cfif>
		
		<cfset Local.fixedData = "ActionDescribeSecurityGroups" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 Local.groupNameListPairs &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="DescribeSecurityGroups"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfif IsDefined("Arguments.groupNameList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.groupNameList#" index="Local.groupName">
					<cfhttpparam type="url" name="GroupName.#Local.index#" value="#Local.groupName#"/>
					<cfset Local.index = Local.index + 1/>
				</cfloop>
			</cfif>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfset Local.response = ArrayNew(1)/>
			
			<cfset Local.securityGroupInfo = XmlParse(CFHTTP.FileContent).DescribeSecurityGroupsResponse.securityGroupInfo.item/>
			
			<cfloop index="Local.i" from="1" to="#ArrayLen(Local.securityGroupInfo)#">
				<cfset Local.response[Local.i] = StructNew()/>
				<cfset Local.response[Local.i].ownerId = Local.securityGroupInfo[Local.i].ownerId.XmlText/>
				<cfset Local.response[Local.i].groupName = Local.securityGroupInfo[Local.i].groupName.XmlText/>
				<cfset Local.response[Local.i].ipPermissions = ArrayNew(1)/>
				<cfset Local.ipPermissions = Local.securityGroupInfo[Local.i].ipPermissions.item/>				
				<cfloop index="Local.j" from="1" to="#ArrayLen(Local.ipPermissions)#">
					<cfset Local.response[Local.i].ipPermissions[Local.j] = StructNew()/>
					<cfset Local.response[Local.i].ipPermissions[Local.j].ipProtocol = Local.ipPermissions[Local.j].ipProtocol.XmlText/>
					<cfset Local.response[Local.i].ipPermissions[Local.j].fromPort = Local.ipPermissions[Local.j].fromPort.XmlText/>
					<cfset Local.response[Local.i].ipPermissions[Local.j].toPort = Local.ipPermissions[Local.j].toPort.XmlText/>
					<cfset Local.response[Local.i].ipPermissions[Local.j].groups = ArrayNew(1)/>
					<cfset Local.currentIpPermissions = Local.ipPermissions[Local.j]/>
					<cfif IsDefined("Local.currentIpPermissions.groups.item")>
						<cfset Local.groups = Local.ipPermissions[Local.j].groups.item/>
						<cfloop index="Local.k" from="1" to="#ArrayLen(Local.groups)#">
							<cfset Local.response[Local.i].ipPermissions[Local.j].groups[Local.k] = Local.groups[Local.k].groupName.XmlText/>
						</cfloop>
					</cfif>
					<cfset Local.response[Local.i].ipPermissions[Local.j].ipRanges = ArrayNew(1)/>
					<cfif IsDefined("Local.currentIpPermissions.ipRanges.item")>
						<cfset Local.ipRanges = Local.ipPermissions[Local.j].ipRanges.item/>
						<cfloop index="Local.m" from="1" to="#ArrayLen(Local.ipRanges)#">
						<cftry>	<cfset Local.response[Local.i].ipPermissions[Local.j].groups[Local.k] = Local.ipRanges[Local.m].cidrIp.XmlText/>
						<cfcatch></cfcatch>
						</cftry>
						</cfloop>
					</cfif>
				</cfloop>
			</cfloop>
			
			<cfreturn Local.response/>
		</cfif>
		
	</cffunction>
	
	<cffunction name="getConsoleOutput" output="false" returntype="struct">
		<cfargument name="instanceId" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionGetConsoleOutput" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "InstanceId#Arguments.instanceId#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="GetConsoleOutput"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="InstanceId" value="#Arguments.instanceId#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfset Local.response = StructNew()/>
			
			<cfset Local.getConsoleOutputResponse = XmlParse(CFHTTP.FileContent).GetConsoleOutputResponse/>
			
			<cfset Local.response.instanceId = Local.getConsoleOutputResponse.instanceId.XmlText/>
			<cfset Local.response.timestamp = Local.getConsoleOutputResponse.timestamp.XmlText/>
			<cfset Local.response.output = Local.getConsoleOutputResponse.output/>
			
			<cfreturn Local.response/>
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
			
			<cfset Local.content = XmlSearch(Arguments.content, "//Response/Errors/Error")/>
	
			<cfset Local.errorCode = Local.content[1].Code.XmlText/>
			<cfset Local.errorMessage = Local.content[1].Message.XmlText/>
			
			<!--- Create CF exception from error --->
			
			<cfthrow type="#Local.errorCode#" 
				message="#Local.errorCode#" 
				detail="#Local.errorMessage#"
			/>
		</cfif>
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
			<cfset outStream.write(JavaCast("int", InputBaseN(ch, 16)))>
		</cfloop>
	
		<cfset outStream.flush()>
		<cfset outStream.close()>
	
		<cfreturn outStream.toByteArray()>
	</cffunction>

	<cffunction name="modifyImageAttribute" output="false" returntype="boolean">
		<cfargument name="imageId" type="string" required="true"/>
		<cfargument name="attribute" type="string" required="true"/>
		<cfargument name="operationType" type="string" required="false" hint="Required for launchPermission; valid values are (add|remove)"/>
		<cfargument name="userIdList" type="string" required="false" hint="List of user IDs to add to or remove from the launchPermission attribute; required for launchPermission"/>
		<cfargument name="userGroupList" type="string" required="false" hint="List of user groups to add to or remove from the launchPermission attribute; required for launchPermission"/>
		<cfargument name="productCodeList" type="string" required="false" hint="List of product codes to be attached to the AM; currently only one product code can be associated with an AMIl required for productCodes"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfif IsDefined("Arguments.operationType")>
			<cfset Local.operationTypePair = "OperationType#Arguments.operationType#"/>
		<cfelse>
			<cfset Local.operationTypePair = ""/>
		</cfif>
		
		<cfset Local.userIdListPairs = ""/>

		<cfif IsDefined("Arguments.userIdList")>
			<cfset Local.index = 1/>
			<cfloop list="#Arguments.userIdList#" index="Local.userId">
				<cfset Local.userIdListPairs = Local.userIdListPairs & "UserId.#Local.index##Local.userId#"/>
				<cfset Local.index = Local.index + 1/>
			</cfloop>
		</cfif>
		
		<cfset Local.userGroupListPairs = ""/>
		
		<cfif IsDefined("Arguments.userGroupList")>
			<cfset Local.index = 1/>
			<cfloop list="#Arguments.userGroupList#" index="Local.userGroup">
				<cfset Local.userGroupListPairs = Local.userGroupListPairs & "UserGroup.#Local.index##Local.userGroup#"/>
				<cfset Local.index = Local.index + 1/>
			</cfloop>
		</cfif>
		
		<cfset Local.productCodeListPairs = ""/>
		
		<cfif IsDefined("Arguments.productCodeList")>
			<cfset Local.index = 1/>
			<cfloop list="#Arguments.productCodeList#" index="Local.productCode">
				<cfset Local.productCodeListPairs = Local.productCodeListPairs & "ProductCode.#Local.index##Local.productCode#"/>
				<cfset Local.index = Local.index + 1/>
			</cfloop>
		</cfif>
		
		<cfset Local.fixedData = "ActionModifyImageAttribute" &
								 "Attribute#Arguments.attribute#" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "ImageId#Arguments.imageId#" &
								 Local.operationTypePair &
								 Local.productCodeListPairs &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 Local.userGroupListPairs &
								 Local.userIdListPairs &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="ModifyImageAttribute"/>
			<cfhttpparam type="url" name="Attribute" value="#Arguments.attribute#"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="ImageId" value="#Arguments.imageId#"/>
			<cfif IsDefined("Arguments.operationType")>
				<cfhttpparam type="url" name="OperationType" value="#Arguments.operationType#"/>
			</cfif>
			<cfif IsDefined("Arguments.productCodeList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.productCodeList#" index="Local.productCode">
					<cfhttpparam type="url" name="ProductCode.#Local.index#" value="#Local.productCode#"/>
					<cfset Local.index = Local.index + 1/>
				</cfloop>
			</cfif>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfif IsDefined("Arguments.userGroupList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.userGroupList#" index="Local.userGroup">
					<cfhttpparam type="url" name="UserGroup.#Local.index#" value="#Local.userGroup#"/>
					<cfset Local.index = Local.index + 1/>
				</cfloop>
			</cfif>
			<cfif IsDefined("Arguments.userIdList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.userIdList#" index="Local.userId">
					<cfhttpparam type="url" name="UserId.#Local.index#" value="#Local.userId#"/>
					<cfset Local.index = Local.index + 1/>
				</cfloop>
			</cfif>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).ModifyImageAttributeResponse.return.XmlText/>
		</cfif>
	</cffunction>
	
	<cffunction name="rebootInstances" output="false" returntype="boolean">
		<cfargument name="instanceIdList" type="string" required="true" hint="List of instance IDs"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.instanceIdListPairs = ""/>
		<cfset Local.index = 1/>
		
		<cfloop list="#Arguments.instanceIdList#" index="Local.instanceId">
			<cfset Local.instanceIdListPairs = Local.instanceIdListPairs & "InstanceId.#Local.index##Local.instanceId#"/>
			<cfset Local.index = Local.index + 1/>
		</cfloop>
		
		<cfset Local.fixedData = "ActionRebootInstances" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 Local.instanceIdListPairs &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="RebootInstances"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfset Local.index = 1/>
			<cfloop list="#Arguments.instanceIdList#" index="Local.instanceId">
				<cfhttpparam type="url" name="InstanceId.#Local.index#" value="#Local.instanceId#"/>
			</cfloop>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).RebootInstancesResponse.return.XmlText/>
		</cfif>
	</cffunction>
	
	<cffunction name="registerImage" output="false" returntype="string">
		<cfargument name="imageLocation" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionRegisterImage" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "ImageLocation#Arguments.imageLocation#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="RegisterImage"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="ImageLocation" value="#Arguments.imageLocation#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).RegisterImageResponse.imageId.XmlText/>
		</cfif>
	</cffunction>

	<cffunction name="resetImageAttribute" output="false" returntype="boolean">
		<cfargument name="imageId" type="string" required="true"/>
		<cfargument name="attribute" type="string" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.fixedData = "ActionResetImageAttribute" &
		                         "Attribute#Arguments.attribute#" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 "ImageId#Arguments.imageId#" &
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="ResetImageAttribute"/>
			<cfhttpparam type="url" name="Attribute" value="#Arguments.attribute#"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="ImageId" value="#Arguments.imageId#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).ResetImageAttributeResponse.return.XmlText/>
		</cfif>
	</cffunction>
	
	<cffunction name="revokeSecurityGroupIngress" output="false" returntype="boolean">
		<cfargument name="groupName" type="string" required="true"/>
		<cfargument name="sourceSecurityGroupName" type="string" required="false" hint="Required when revoking user/group pair permission"/>
		<cfargument name="sourceSecurityGroupOwnerId" type="string" required="false" hint="Required when revoking user/group pair permission"/>
		<cfargument name="ipProtocol" type="string" required="false" hint="Required when revoking CIDR IP permission; valid values are (tcp|udp|icmp)"/>
		<cfargument name="fromPort" type="numeric" required="false" hint="Required when revoking CIDR IP permission"/>
		<cfargument name="toPort" type="numeric" required="false" hint="Required when revoking CIDR IP permission"/>
		<cfargument name="cidrIp" type="string" required="false" hint="Required when revoking CIDR IP permission"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfif IsDefined("Arguments.sourceSecurityGroupName")>
			<cfset Local.sourceSecurityGroupNamePair = "SourceSecurityGroupName#Arguments.sourceSecurityGroupName#"/>
		<cfelse>
			<cfset Local.sourceSecurityGroupNamePair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.sourceSecurityGroupOwnerId")>
			<cfset Local.sourceSecurityGroupOwnerIdPair = "SourceSecurityGroupOwnerId#Arguments.sourceSecurityGroupOwnerId#"/>
		<cfelse>
			<cfset Local.sourceSecurityGroupOwnerIdPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.ipProtocol")>
			<cfset Local.ipProtocolPair = "IpProtocol#Arguments.ipProtocol#"/>
		<cfelse>
			<cfset Local.ipProtocolPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.fromPort")>
			<cfset Local.fromPortPair = "FromPort#Arguments.fromPort#"/>
		<cfelse>
			<cfset Local.fromPortPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.toPort")>
			<cfset Local.toPortPair = "ToPort#Arguments.toPort#"/>
		<cfelse>
			<cfset Local.toPortPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.cidrIp")>
			<cfset Local.cidrIpPair = "CidrIp#Arguments.cidrIp#"/>
		<cfelse>
			<cfset Local.cidrIpPair = ""/>
		</cfif>
		
		<cfset Local.fixedData = "ActionRevokeSecurityGroupIngress" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 Local.cidrIpPair &
								 Local.fromPortPair &
								 "GroupName#Arguments.groupName#" &
								 Local.ipProtocolPair &
								 "SignatureVersion1" &
								 Local.sourceSecurityGroupNamePair &
								 Local.sourceSecurityGroupOwnerIdPair &
								 "Timestamp#Local.dateTimeString#" &
								 Local.toPortPair &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="RevokeSecurityGroupIngress"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfif IsDefined("Arguments.cidrIp")>
				<cfhttpparam type="url" name="CidrIp" value="#Arguments.cidrIp#"/>
			</cfif>
			<cfif IsDefined("Arguments.fromPort")>
				<cfhttpparam type="url" name="FromPort" value="#Arguments.fromPort#"/>
			</cfif>
			<cfhttpparam type="url" name="GroupName" value="#Arguments.groupName#"/>
			<cfif IsDefined("Arguments.ipProtocol")>
				<cfhttpparam type="url" name="IpProtocol" value="#Arguments.ipProtocol#"/>
			</cfif>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfif IsDefined("Arguments.sourceSecurityGroupName")>
				<cfhttpparam type="url" name="SourceSecurityGroupName" value="#Arguments.sourceSecurityGroupName#"/>
			</cfif>
			<cfif IsDefined("Arguments.sourceSecurityGroupOwnerId")>
				<cfhttpparam type="url" name="SourceSecurityGroupOwnerId" value="#Arguments.sourceSecurityGroupOwnerId#"/>
			</cfif>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfif IsDefined("Arguments.toPort")>
				<cfhttpparam type="url" name="ToPort" value="#Arguments.toPort#"/>
			</cfif>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfreturn XmlParse(CFHTTP.FileContent).RevokeSecurityGroupIngressResponse.return.XmlText/>
		</cfif>
	</cffunction>
	
	<cffunction name="runInstances" output="false" returntype="struct">
		<cfargument name="imageId" type="string" required="true"/>
		<cfargument name="minCount" type="numeric" required="true"/>
		<cfargument name="maxCount" type="numeric" required="true"/>
		<cfargument name="keyName" type="string" required="false"/>
		<cfargument name="securityGroupList" type="string" required="false" hint="List of names of the security groups with which to associate the instances"/>
		<cfargument name="userData" type="string" required="false"/>
		<cfargument name="addressingType" type="string" required="false"/>
		<cfargument name="instanceType" type="string" required="false" hint="Options are (m1.small|m1.large|m1.xlarge)"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfif IsDefined("Arguments.keyName")>
			<cfset Local.keyNamePair = "KeyName#Arguments.keyName#"/>
		<cfelse>
			<cfset Local.keyNamePair = ""/>
		</cfif>
		
		<cfset Local.securityGroupListPairs = ""/>

		<cfif IsDefined("Arguments.securityGroupList")>
			<cfset Local.index = 1/>
			<cfloop list="#Arguments.securityGroupList#" index="Local.securityGroup">
				<cfset Local.securityGroupListPairs = Local.securityGroupListPairs & "SecurityGroup.#Local.index##Local.securityGroup#"/>
				<cfset Local.index = Local.index + 1/>
			</cfloop>
		</cfif>
		
		<cfif IsDefined("Arguments.userData")>
			<cfset Local.userDataPair = "UserData#Arguments.userData#"/>
		<cfelse>
			<cfset Local.userDataPair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.addressingType")>
			<cfset Local.addressingTypePair = "AddressingType#Arguments.addressingType#"/>
		<cfelse>
			<cfset Local.addressingTypePair = ""/>
		</cfif>
		
		<cfif IsDefined("Arguments.instanceType")>
			<cfset Local.instanceTypePair = "InstanceType#Arguments.instanceType#"/>
		<cfelse>
			<cfset Local.instanceTypePair = ""/>
		</cfif>
		
		<cfset Local.fixedData = "ActionRunInstances" & 
								 Local.addressingTypePair & 
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" & 
								 "ImageId#Arguments.imageId#" &
								 Local.instanceTypePair & 
								 Local.keyNamePair &
								 "MaxCount#Arguments.maxCount#" & 
								 "MinCount#Arguments.minCount#" & 
								 Local.securityGroupListPairs & 
								 "SignatureVersion1" & 
								 "Timestamp#Local.dateTimeString#" &
								 Local.userDataPair & 
								 "Version#Variables.ec2Version#"/>
								 
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="RunInstances"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="ImageId" value="#Arguments.imageId#"/>
			<cfhttpparam type="url" name="MinCount" value="#Arguments.minCount#"/>
			<cfhttpparam type="url" name="MaxCount" value="#Arguments.maxCount#"/>
			<cfif IsDefined("Arguments.keyName")>
				<cfhttpparam type="url" name="KeyName" value="#Arguments.keyName#"/>
			</cfif>
			<cfif IsDefined("Arguments.securityGroupList")>
				<cfset Local.index = 1/>
				<cfloop list="#Arguments.securityGroupList#" index="Local.securityGroup">
					<cfhttpparam type="url" name="SecurityGroup.#Local.index#" value="#Local.securityGroup#"/>
					<cfset Local.index = Local.index + 1/>
				</cfloop>
			</cfif>
			<cfif IsDefined("Arguments.userData")>
				<cfhttpparam type="url" name="UserData" value="#Arguments.userData#"/>
			</cfif>
			<cfif IsDefined("Arguments.addressingType")>
				<cfhttpparam type="url" name="AddressingType" value="#Arguments.addressingType#"/>
			</cfif>
			<cfif IsDefined("Arguments.instanceType")>
				<cfhttpparam type="url" name="InstanceType" value="#Arguments.instanceType#"/>
			</cfif>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfset Local.response = StructNew()/>

			<cfset Local.runInstancesResponse = XmlParse(CFHTTP.FileContent).RunInstancesResponse/>
			<cfset Local.runInstancesResponse = Local.runInstancesResponse[1]/>
			
			<cfset Local.response.reservationId = Local.runInstancesResponse.reservationId.XmlText/>
			<cfset Local.response.ownerId = Local.runInstancesResponse.ownerId.XmlText/>
			<cfset Local.response.groupSet = ArrayNew(1)/>
			<cfset Local.groupSet = Local.runInstancesResponse.groupSet.item/>
			<cfloop index="Local.i" from="1" to="#ArrayLen(Local.groupSet)#">
				<cfset Local.response.groupSet[Local.i] = Local.groupSet[Local.i].XmlText/>
			</cfloop>
			<cfset Local.response.instancesSet = ArrayNew(1)/>
			<cfset Local.instancesSet = Local.runInstancesResponse.instancesSet.item/>
			<cfloop index="Local.j" from="1" to="#ArrayLen(Local.instancesSet)#">
				<cfset Local.response.instancesSet[Local.j] = StructNew()/>
				<cfset Local.response.instancesSet[Local.j].instanceId = Local.instancesSet[Local.j].instanceId.XmlText/>
				<cfset Local.response.instancesSet[Local.j].instanceState = StructNew()/>
				<cfset Local.response.instancesSet[Local.j].instanceState.code = Local.instancesSet[Local.j].instanceState.code.XmlText/>
				<cfset Local.response.instancesSet[Local.j].instanceState.name = Local.instancesSet[Local.j].instanceState.name.XmlText/>
				<cfset Local.response.instancesSet[Local.j].privateDnsName = Local.instancesSet[Local.j].privateDnsName.XmlText/>
				<cfset Local.response.instancesSet[Local.j].dnsName = Local.instancesSet[Local.j].dnsName.XmlText/>
				<!---<cfset Local.response.instancesSet[Local.j].keyName = Local.instancesSet[Local.j].keyName.XmlText/>--->
				<cfset Local.response.instancesSet[Local.j].reason = Local.instancesSet[Local.j].reason.XmlText/>
				<cfset Local.response.instancesSet[Local.j].amiLaunchIndex = Local.instancesSet[Local.j].amiLaunchIndex.XmlText/>
				<cfset Local.response.instancesSet[Local.j].instanceType = Local.instancesSet[Local.j].instanceType.XmlText/>
				<cfset Local.response.instancesSet[Local.j].launchTime = Local.instancesSet[Local.j].launchTime.XmlText/>
			</cfloop>
			
			<cfreturn Local.response/>
		</cfif>
	</cffunction>
	
	<cffunction name="terminateInstances" output="false" returntype="array">
		<cfargument name="instanceIdList" type="string" required="true" hint="List of instance IDs"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.dateTimeString = zuluDateTimeFormat(Now())/>
		
		<cfset Local.instanceIdListPairs = ""/>
		<cfset Local.index = 1/>
		
		<cfloop list="#Arguments.instanceIdList#" index="Local.instanceId">
			<cfset Local.instanceIdListPairs = Local.instanceIdListPairs & "InstanceId.#Local.index##Local.instanceId#"/>
			<cfset Local.index = Local.index + 1/>
		</cfloop>
		
		<cfset Local.fixedData = "ActionTerminateInstances" &
		                         "AWSAccessKeyId#Variables.awsAccessKeyId#" &
								 Local.instanceIdListPairs & 
								 "SignatureVersion1" &
								 "Timestamp#Local.dateTimeString#" &
								 "Version#Variables.ec2Version#"/>
		
		<cfset Local.signature = createSignature(Local.fixedData)/>
		
		<cfhttp method="GET" url="#Variables.serviceUrl#" charset="utf-8">
			<cfhttpparam type="url" name="Action" value="TerminateInstances"/>
			<cfhttpparam type="url" name="AWSAccessKeyId" value="#Variables.awsAccessKeyId#"/>
			<cfset Local.index = 1/>
			<cfloop list="#Arguments.instanceIdList#" index="Local.instanceId">
				<cfhttpparam type="url" name="InstanceId.#Local.index#" value="#Local.instanceId#"/>
				<cfset Local.index = Local.index + 1/>
			</cfloop>
			<cfhttpparam type="url" name="Signature" value="#Local.signature#"/>
			<cfhttpparam type="url" name="SignatureVersion" value="1"/>
			<cfhttpparam type="url" name="Timestamp" value="#Local.dateTimeString#"/>
			<cfhttpparam type="url" name="Version" value="#Variables.ec2Version#"/>
		</cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
			<cfinvoke method="handleErrors"
				content="#CFHTTP.FileContent#"
			/>
		<cfelse>
			<cfset Local.terminateInstancesResponse = Local.terminateInstancesResponse[1]/>
			
			<cfset Local.instancesSet = Local.terminateInstancesResponse.instancesSet.item/>
			
			<cfset Local.response = ArrayNew(1)/>
			
			<cfloop index="Local.i" from="1" to="#ArrayLen(Local.instancesSet)#">
				<cfset Local.response[Local.i] = StructNew()/>
				<cfset Local.response[Local.i].instanceId = Local.instancesSet[Local.i].instanceId.XmlText/>
				
				<cfset Local.response[Local.i].shutdownState = StructNew()/>
				<cfset Local.response[Local.i].shutdownState.code = Local.instancesSet[Local.i].shutdownState.code.XmlText/>
				<cfset Local.response[Local.i].shutdownState.name = Local.instancesSet[Local.i].shutdownState.name.XmlText/>
				
				<cfset Local.response[Local.i].previousState = StructNew()/>
				<cfset Local.response[Local.i].previousState.code = Local.instancesSet[Local.i].previousState.code.XmlText/>
				<cfset Local.response[Local.i].previousState.name = Local.instancesSet[Local.i].previousState.name.XmlText/>
			</cfloop>
			
			<cfreturn Local.response/>
		</cfif>
	</cffunction>
	
	<cffunction name="zuluDateTimeFormat" output="false" returntype="string" access="private">
		<cfargument name="dateTime" type="date" required="true"/>
		
		<cfset var Local = StructNew()/>
		
		<cfset Local.utcDate = DateAdd("s", GetTimeZoneInfo().utcTotalOffset, Arguments.dateTime)/>
		
		<cfreturn DateFormat(Local.utcDate, "yyyy-mm-dd") & "T" & TimeFormat(Local.utcDate, "HH:mm:ss.l") & "Z"/>
	</cffunction>
	
	<cffunction name="createDefaultCFPolicy" hint="added by Tim Cunningham for AWS Project">
		<cfset local.defaultGroup = describeSecurityGroups()>
		<cfset local.i = 1>
		<cfloop array="#local.defaultGroup#" index="local.group">
			<cfif local.group.groupName IS "default">
				<cfset local.defaultGroup = local.defaultGroup[local.i]>
				<cfbreak>
			</cfif>hint="added by Tim Cunningham for AWS Project"
			<cfset local.i = local.i + 1>
		</cfloop>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp",	fromPort="22", 		toPort="22", 	cidrIP="0.0.0.0/0")>		
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="80", 		toPort="80", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="443",		toPort="443", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="995",		toPort="995", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="1433",	toPort="1433", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="3306",	toPort="3306", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="389",		toPort="389", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="3389",	toPort="3389", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="8985",	toPort="8985", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="20",		toPort="21", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="110",		toPort="110", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="143",		toPort="143", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="843",		toPort="843", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="1024",	toPort="1024", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="1841",	toPort="1841", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="3128",	toPort="3128", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="4101",	toPort="4101", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="8012",	toPort="8016", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="8500",	toPort="8500", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="8575",	toPort="8575", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="49152",	toPort="65534", cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="1234",	toPort="1234", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="50000",	toPort="50000", cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="9090",	toPort="9090", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="9088",	toPort="9088", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="1432",	toPort="1432", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="20002",	toPort="20002", cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="5432",	toPort="5432", 	cidrIP="0.0.0.0/0")>
		<cfset addpolicy(groupStruct="#local.defaultGroup#", 	ipProtocol="tcp", 	fromPort="1521",	toPort="1521", 	cidrIP="0.0.0.0/0")>
		<cfreturn>
	</cffunction>
	
	<cffunction name="addPolicy" hint="added by Tim Cunningham for AWS Project">
		<cfargument name="groupStruct" type="struct" required="true"/>
		<cfargument name="sourceSecurityGroupName" type="string" required="false" hint="Required when authorizing user/group pair permission"/>
		<cfargument name="sourceSecurityGroupOwnerId" type="string" required="false" hint="Required when authorizing user/group pair permission"/>
		<cfargument name="ipProtocol" type="string" required="false" hint="Required when authorizing CIDR IP permission; valid values are (tcp|udp|icmp)"/>
		<cfargument name="fromPort" type="numeric" required="false" hint="Required when authorizing CIDR IP permission"/>
		<cfargument name="toPort" type="numeric" required="false" hint="Required when authorizing CIDR IP permission"/>
		<cfargument name="cidrIP" type="string" required="false" hint="Required when authorizing CIDR IP permission"/>
		<cfset local.groupName = arguments.groupStruct.groupName>
		<cfset local.i = 1>
		
		<cfloop array="#arguments.groupStruct.IPPermissions#" index="local.permission">
			<cfif local.permission.fromPort IS arguments.fromPort
				AND local.permission.ipProtocol IS arguments.ipProtocol
				AND local.permission.fromPort IS arguments.fromPort
				AND local.permission.toPort IS arguments.toPort>
				<cfreturn false>
				<cfbreak>
			</cfif>
			<cfset local.i = local.i + 1>
		</cfloop>
		
		<cfreturn authorizeSecurityGroupIngress(groupName="#local.groupName#",
				ipProtocol="#arguments.ipProtocol#",
				fromPort="#arguments.fromPort#",
				toPort="#arguments.toPort#",
				cidrIP="#arguments.cidrIP#")>
		
		
		
	
	</cffunction>
</cfcomponent>