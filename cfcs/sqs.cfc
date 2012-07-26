<cfcomponent output="false">

<!---
Amazon SQS CFC for SQS Version 2008-01-01
Re-written, 2008, by David C. Smith (dcsmith@hotmail.com) from the original CFC by Jeffrey Pratt, 2007 (http://sqscfc.riaforge.org/)
Released: March 2008
License: Apache License, Version 2 (http://www.apache.org/licenses/LICENSE-2.0)
--->


	<cfset This.sqsVersion = "2008-01-01"/>
	<cfset This.serviceUrl = "http://queue.amazonaws.com"/>

	<!--- These first 3 functions serve the rest: init, zuluDateTime, createSignature --->
    
    <cffunction name="init" output="false" returntype="sqs"  hint="Returns an instance of the CFC initialized.">
		<cfargument name="awsAccessKeyId" type="string" required="true"/>
		<cfargument name="secretAccessKey" type="string" required="true"/>
		
		<cfset This.awsAccessKeyId = Arguments.awsAccessKeyId/>
		<cfset This.secretAccessKey = Arguments.secretAccessKey/>
		
		<cfreturn This/>
	</cffunction>
    
    
    <cffunction name="zuluDateTimeFormat" output="false" returntype="string" access="private">
        <cfargument name="dateTime" type="date" required="true"/>
        
        <cfset var Function = StructNew()/>
        <cfset Function.utcDate = DateAdd("s", GetTimeZoneInfo().utcTotalOffset, Arguments.dateTime)/>
        
        <cfreturn DateFormat(Function.utcDate, "yyyy-mm-dd") & "T" & TimeFormat(Function.utcDate, "HH:mm:ss.l") & "Z"/>
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
			<cfinvokeargument name="key" value="#This.secretAccessKey#"/>
		</cfinvoke>
		
		<cfreturn ToBase64(hexToBin(Function.digest))/>
	</cffunction>






	<!--- WSDL Actions for Queues:
        CreateQueue 
        DeleteQueue 
        ListQueues 
        GetQueueAttributes 
        SetQueueAttributes --->
    
    <!--- API Reference: http://docs.amazonwebservices.com/AWSSimpleQueueService/2008-01-01/SQSDeveloperGuide/ --->
    

    <cffunction name="createQueue" output="true" returntype="string">
        <cfargument name="queueName" type="string" required="true"/>
        <cfargument name="defaultVisibilityTimeout" type="numeric" required="false"/>
        
        <!--- create a varred "Function" scope for all function variables --->
		<cfset var Function = StructNew()/>
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfif IsDefined("Arguments.defaultVisibilityTimeout")>
            <cfset Function.defaultVisibilityTimeoutPair = "DefaultVisibilityTimeout#Arguments.defaultVisibilityTimeout#"/>
        <cfelse>
            <cfset Function.defaultVisibilityTimeoutPair = ""/>
        </cfif>
        
        <!--- Build signature string --->
        <cfset Function.fixedData = "ActionCreateQueue" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    Function.defaultVisibilityTimeoutPair &
                                    "QueueName#Arguments.queueName#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.sqsVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <!--- Build URL string sent to AWS --->
        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="CreateQueue"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfif IsDefined("Arguments.defaultVisibilityTimeout")>
                <cfhttpparam type="url" name="DefaultVisibilityTimeout" value="#Arguments.defaultVisibilityTimeout#"/>
            </cfif>
            <cfhttpparam type="url" name="QueueName" value="#Arguments.queueName#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.sqsVersion#"/>
        </cfhttp>
        
        
        <!--- Handle errors from the AWS response --->
        <cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
            <!--- If no errors, display response --->
			<cfset Function.queue = XmlSearch(CFHTTP.FileContent, "//:QueueUrl")/>		
            <cfreturn Function.queue[1].XmlText/>
        </cfif>
    </cffunction>
        
    



    <cffunction name="deleteQueue" output="true" returntype="string">
        <cfargument name="uri" type="string" required="true"/>
        
        <cfset var Function = StructNew()/>
        
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset Function.fixedData = "ActionDeleteQueue" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.sqsVersion#"/>
    
        <cfset Function.signature = createSignature(Function.fixedData)/>
        <cfhttp method="GET" url="#Arguments.uri#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="DeleteQueue"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.sqsVersion#"/>
        </cfhttp>
        

		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
        <cfreturn XmlParse(CFHTTP.FileContent).DeleteQueueResponse.ResponseMetadata.RequestId.XmlText/>
		</cfif>
    </cffunction>
    



    <cffunction name="listQueues" output="true" returntype="array">
        <cfargument name="queueNamePrefix" type="string" required="false"/>
        
        <cfset var Function = StructNew()/>
        
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfif IsDefined("Arguments.queueNamePrefix")>
            <cfset Function.queueNamePrefixPair = "QueueNamePrefix#Arguments.queueNamePrefix#"/>
        <cfelse>
            <cfset Function.queueNamePrefixPair = ""/>
        </cfif>
        
        <cfset Function.fixedData = "ActionListQueues" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    Function.queueNamePrefixPair &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.sqsVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="ListQueues"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfif IsDefined("Arguments.queueNamePrefix")>
                <cfhttpparam type="url" name="QueueNamePrefix" value="#Arguments.queueNamePrefix#"/>
            </cfif>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.sqsVersion#"/>
        </cfhttp>
		
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
         
        <cfelse>		
            <cfset Function.queueUrls = XmlSearch(CFHTTP.FileContent, "//:QueueUrl")/>
            
            <cfset Function.queueUrlsCount = ArrayLen(Function.queueUrls)/>
            
            <cfset Function.queues = ArrayNew(1)/>
            <cfloop index="i" from="1" to="#Function.queueUrlsCount#">
                <cfset ArrayAppend(Function.queues, Function.queueUrls[i].XmlText)/>
            </cfloop>
            
            <cfreturn Function.queues/>
        </cfif>
    </cffunction>
    



    <cffunction name="getQueueAttributes" output="false" returntype="struct">
        <cfargument name="uri" type="string" required="true"/>
        <cfargument name="attributeName" type="string" required="true"/>
        
        <cfset var Function = StructNew()/>
        
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset Function.fixedData = "ActionGetQueueAttributes" &
                                    "AttributeName#Arguments.attributeName#" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.sqsVersion#"/>
    
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#Arguments.uri#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="GetQueueAttributes"/>
            <cfhttpparam type="url" name="AttributeName" value="#Arguments.attributeName#"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.sqsVersion#"/>
        </cfhttp>
        
        <cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
            <cfset Function.attributedValues = XmlSearch(CFHTTP.FileContent, "//:Attribute")/>
            <cfset Function.attributedValuesCount = ArrayLen(Function.attributedValues)/>
            
            <cfset Function.attributes = StructNew()/>
            
            <cfloop index="i" from="1" to="#Function.attributedValuesCount#">
                <cfset Function.attributes[Function.attributedValues[i].Name.XmlText] = Function.attributedValues[i].Value.XmlText/>
            </cfloop>
            
            <cfreturn Function.attributes/>
        </cfif>
    </cffunction>
    
    



    <cffunction name="setQueueAttributes" output="true" returntype="void">
        <cfargument name="uri" type="string" required="true"/>
        <cfargument name="name" type="string" required="true"/>
        <cfargument name="value" type="string" required="true"/>
        
        <cfset var Function = StructNew()/>
        
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset Function.fixedData = "ActionSetQueueAttributes" &
                                    "Attribute#Arguments.attribute#" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Value#Arguments.value#" &
                                    "Version#This.sqsVersion#"/>
    
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#Arguments.uri#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="SetQueueAttributes"/>
            <cfhttpparam type="url" name="Attribute.Name" value="#Arguments.name#"/>
            <cfhttpparam type="url" name="Attribute.Value" value="#Arguments.value#"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.sqsVersion#"/>
        </cfhttp>
        
        <cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
         <cfelse>
        	<cfreturn XmlParse(CFHTTP.FileContent).setQueueAttributesResponse.ResponseMetadata.RequestId.XmlText/>
		</cfif>
    </cffunction>
    



    <!--- WSDL Actions for Messages:
        SendMessage 
        ReceiveMessage 
        DeleteMessage --->
    
    
    <cffunction name="sendMessage" output="false" returntype="string">
        <cfargument name="uri" type="string" required="true"/>
        <cfargument name="messageBody" type="string" required="true"/>
        
        <cfset var Function = StructNew()/>
        
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset Function.fixedData = "ActionSendMessage" &
									"AWSAccessKeyId#This.awsAccessKeyId#" &
                                    "MessageBody#Arguments.messageBody#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.sqsVersion#"/>
    
        <cfset Function.signature = createSignature(Function.fixedData)/>
        <cfhttp method="GET" url="#Arguments.uri#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="SendMessage"/>
            <cfhttpparam type="url" name="MessageBody" value="#Arguments.messageBody#"/>            
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.sqsVersion#"/>
        </cfhttp>
        
	
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
        <cfreturn XmlParse(CFHTTP.FileContent).sendMessageResponse.SendMessageResult.MessageID.XmlText/>
		</cfif>
    </cffunction>
    
    



    <cffunction name="receiveMessage" output="false" returntype="array">
        <cfargument name="uri" type="string" required="true"/>
        <cfargument name="maxNumberOfMessages" type="numeric" required="false"/>
        <cfargument name="visibilityTimeout" type="numeric" required="false"/>
        
        <cfset var Function = StructNew()/>
        
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfif IsDefined("Arguments.maxNumberOfMessages")>
            <cfset Function.maxNumberOfMessagesPair = "maxNumberOfMessages#Arguments.maxNumberOfMessages#"/>
        <cfelse>
            <cfset Function.maxNumberOfMessagesPair = ""/>
        </cfif>
        
        <cfif IsDefined("Arguments.visibilityTimeout")>
            <cfset Function.visibilityTimeoutPair = "VisibilityTimeout#Arguments.visibilityTimeout#"/>
        <cfelse>
            <cfset Function.visibilityTimeoutPair = ""/>
        </cfif>
        
        <cfset Function.fixedData = "ActionReceiveMessage" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    Function.maxNumberOfMessagesPair &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.sqsVersion#" &
                                    Function.visibilityTimeoutPair/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#Arguments.uri#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="ReceiveMessage"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfif IsDefined("Arguments.maxNumberOfMessages")>
                <cfhttpparam type="url" name="maxNumberOfMessages" value="#Arguments.maxNumberOfMessages#"/>
            </cfif>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.sqsVersion#"/>
            <cfif IsDefined("Arguments.visibilityTimeout")>
                <cfhttpparam type="url" name="VisibilityTimeout" value="#Arguments.visibilityTimeout#"/>
            </cfif>
        </cfhttp>
        
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        
		<cfelse>
			<cfset Function.messageNode = XmlSearch(CFHTTP.FileContent, "//:Message")/>
            <cfset Function.messages = ArrayNew(1)/>
            <cfset Function.messageNodeCount = ArrayLen(Function.messageNode)/>
            
            <cfloop index="i" from="1" to="#Function.messageNodeCount#">
                <cfset Function.message = StructNew()/>
                <cfset Function.message.id = Function.messageNode[i].MessageId.XmlText/>
                <cfset Function.message.body = Function.messageNode[i].Body.XmlText/>	
                <cfset Function.messages[i] = Function.message/>
            </cfloop>
            
            <cfreturn Function.messages/>
        </cfif>
    </cffunction>
    
    



    <cffunction name="deleteMessage" output="true" returntype="void">
        <cfargument name="uri" type="string" required="true"/>
        <cfargument name="receiptHandle" type="string" required="true"/>
        
        <cfset var Function = StructNew()/>
        
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset Function.fixedData = "ActionDeleteMessage" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    "receiptHandle#Arguments.receiptHandle#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.sqsVersion#"/>
    
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#Arguments.uri#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="DeleteMessage"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="receiptHandle" value="#Arguments.receiptHandle#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.sqsVersion#"/>
        </cfhttp>
        
        <cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
        	<cfreturn XmlParse(CFHTTP.FileContent).deleteMessageResponse.return.XmlText/>
		</cfif>
    </cffunction>
        



	<!--- Error Handling --->       
        
    <cffunction name="handleErrors" output="true" returntype="void" access="private">
        <cfargument name="content" type="string" required="true"/>
    
        <cfset var Function = StructNew()/>
        
        <cfif Arguments.content is "Connection failure">	
            <cfthrow type="ConnectionFailureException" 
                message="Connection failure." 
                detail="No connection could be made to ""#Arguments.uri#""."
            />
        <cfelse>
            
            <cfset Function.content = XmlSearch(Arguments.content, "//ErrorResponse/Error")/>
            <cfset Function.errorCode = Function.content[1].Code.XmlText/>
            <cfset Function.errorMessage = Function.content[1].Message.XmlText/>
            
            <cfthrow type="#Function.errorCode#" 
                message="#Function.errorCode#" 
                detail="#Function.errorMessage#"
            />
        </cfif>
    </cffunction>

</cfcomponent>

