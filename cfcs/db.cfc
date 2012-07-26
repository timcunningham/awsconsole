<cfcomponent output="false">

<!---
Amazon SimpleDB CFC for SimpleDB Version 2007-11-07
Author: David Smith (dcsmith@hotmail.com)
Released: March 2008
License: Apache License, Version 2 (http://www.apache.org/licenses/LICENSE-2.0)
--->


	<cfset This.dbVersion = "2007-11-07"/>
	<cfset This.serviceUrl = "http://sdb.amazonaws.com"/>

	<!--- These first 4 functions serve the rest: init, zuluDateTime, hexToBin, createSignature --->
    
    <cffunction name="init" output="false" returntype="db"  hint="Returns an instance of the CFC initialized.">
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


	<!--- WSDL Actions for SimpleDB:
		 CreateDomain 
		 DeleteDomain 
		 ListDomains 
		 PutAttributes 
		 DeleteAttributes 
		 GetAttributes 
		 Query --->
    
    <!--- API Reference: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/ --->
    

    <cffunction name="createDomain" output="true" returntype="string">
        <cfargument name="domainName" type="string" required="true"/>
        
		<!--- create a varred "Function" scope for all function variables --->
        <cfset var Function = StructNew()/>
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <!--- Build signature string --->
        <cfset Function.fixedData = "ActionCreateDomain" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    "DomainName#Arguments.domainName#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.dbVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>

		<!--- Build URL string sent to AWS --->        
        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="CreateDomain"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="DomainName" value="#Arguments.domainName#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.dbVersion#"/>
        </cfhttp>
        
        
        <!--- Handle errors from the AWS response --->
		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
        	<!--- If no errors, display response --->
			<cfreturn XmlParse(CFHTTP.FileContent).CreateDomainResponse.ResponseMetadata.BoxUsage.XmlText/>
    	</cfif>
    </cffunction>






        
    <cffunction name="deleteDomain" output="true" returntype="string">
        <cfargument name="domainName" type="string" required="true"/>
        
        <cfset var Function = StructNew()/>
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset Function.fixedData = "ActionDeleteDomain" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    "DomainName#Arguments.domainName#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.dbVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="DeleteDomain"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="DomainName" value="#Arguments.domainName#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.dbVersion#"/>
        </cfhttp>
        
        
        <cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
            <cfreturn XmlParse(CFHTTP.FileContent).DeleteDomainResponse.ResponseMetadata.BoxUsage.XmlText/>
    	</cfif>
    </cffunction>
    






    <cffunction name="listDomains" output="true" returntype="array">
        <cfargument name="maxNumberOfDomains" type="string" required="false"/>
        <cfargument name="nextToken" type="string" required="false"/>
        
        <cfset var Function = StructNew()/>
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfif IsDefined("Arguments.maxNumberOfDomains")>
            <cfset Function.maxNumberOfDomainsPair = "MaxNumberOfDomains#Arguments.maxNumberOfDomains#"/>
        <cfelse>
            <cfset Function.maxNumberOfDomainsPair = ""/>
        </cfif>
        
        <cfif IsDefined("Arguments.nextToken")>
            <cfset Function.nextTokenPair = "NextToken#Arguments.nextToken#"/>
        <cfelse>
            <cfset Function.nextTokenPair = ""/>
        </cfif>
		
		<cfset Function.fixedData = "ActionListDomains" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    Function.maxNumberOfDomainsPair &
									Function.nextTokenPair &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.dbVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="ListDomains"/>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfif IsDefined("Arguments.maxNumberOfDomains")>
                <cfhttpparam type="url" name="maxNumberOfDomains" value="#Arguments.maxNumberOfDomains#"/>
            </cfif>
            <cfif IsDefined("Arguments.nextTokne")>
                <cfhttpparam type="url" name="nextToken" value="#Arguments.nextToken#"/>
            </cfif>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.dbVersion#"/>
        </cfhttp>
        

		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
            <cfset Function.listDomains = XmlSearch(CFHTTP.FileContent, "//:DomainName")/>
            
			<cfset Function.domains = arrayNew(1)/>
            
            <cfloop index="i" from="1" to="#ArrayLen(Function.listDomains)#">
            	<cfset Function.domain = StructNew()/>
                <cfset Function.domain.DomainName = Function.listDomains[i].XmlText/>
                <cfset Function.domains[i] = Function.domain/>
            </cfloop>

            <cfreturn Function.domains/>
        </cfif>
    </cffunction>




    

	<cffunction name="putAttributes" output="true" returntype="string">
        <cfargument name="attributeNameList" type="string" required="true"/>
        <cfargument name="attributeValueList" type="string" required="true"/>
        <cfargument name="itemName" type="string" required="true"/>
        <cfargument name="domainName" type="string" required="true"/>
        
        <cfset var Function = StructNew()/>
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset myNameArray = ListToArray(attributeNameList, ",", "true")>
        <cfset myValueArray = ListToArray(attributeValueList, "|", "true")>
        
        <cfset index = 1/>
		<cfset attributeNameValuePairs=""/>
        <cfloop from="1" to="#ArrayLen(myNameArray)#" index="i">
			<cfif #myNameArray[i]# eq "">#deleteAttributes(Arguments.domainName, Arguments.itemName)#<cfelse>
				<cfif #myNameArray[i]# CONTAINS "attribute.">
                	<!--- Below we have to rewrite the name/value pairs being passed into the signature so that they fall into the required alphabetically
					listed name/value pairs (i.e., "N"ame, "R"eplace, "V"alue).  Really what we're doing is removing the *previous* name/value pair, as it would be
					a duplicate since Replace shows up in the array list AFTER the name/value pair you want to update.  So you have to go forwards, then
					backwards to clean up the list.  Hey, if there is a better way with less overhead, go for it! ---> 
                    <cfset attributeNameValuePairs = ListAppend(attributeNameValuePairs, "Attribute.#index-1#.Name#myNameArray[i-1]#Attribute.#index-1#.ReplacetrueAttribute.#index-1#.Value#myValueArray[i-1]#", "|")/>
					<cfset attributeNameValuePairs = ListDeleteAt(attributeNameValuePairs, index-1, "|")/>
                    <cfset index = index-1/>
                <cfelse>
                    <cfset attributeNameValuePairs = ListAppend(attributeNameValuePairs, "Attribute.#index#.Name#myNameArray[i]#Attribute.#index#.Value#myValueArray[i]#", "|")/>
				</cfif>
            </cfif>
        <cfset index = index + 1/>
		</cfloop>
        
        <cfset function.attributeNameValuePairs = ListChangeDelims(attributeNameValuePairs, "", "|")>
        
        <cfset Function.fixedData = "ActionPutAttributes" &
                                    function.attributeNameValuePairs &
									"AWSAccessKeyId#This.awsAccessKeyId#" &
									"DomainName#Arguments.domainName#" &
									"ItemName#Arguments.itemName#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.dbVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
       <!---DEBUG CODE IF NEEDED:
        <p><strong>Function.fixedData:</strong>			#Function.fixedData#
        <p>Arguments.attributeNameList: #Arguments.attributeNameList#<br>
        <p>Arguments.attributeValueList: #Arguments.attributeValueList#<br><br>

        <p>attributeNameValuePairs: #attributeNameValuePairs#<br>
        <strong>function.attributeNameValuePairs:</strong> 	#function.attributeNameValuePairs#<br>
        Function.signature: #Function.signature#<br><br>

        <br /><a href="mydb.cfm">Refresh</a><br><br>--->


        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="PutAttributes"/>

        	<cfset index=1/>
            <cfloop from="1" to="#ArrayLen(myNameArray)#" index="i">
                    <cfif #myNameArray[i]# CONTAINS "attribute.">
                        <cfhttpparam type="url" name="Attribute.#index-1#.Replace" value="true"/>
                        <cfset index=index-1/>
                    <cfelse>
                    	<cfhttpparam type="url" name="Attribute.#index#.Name" value="#myNameArray[i]#"/>
                        <cfhttpparam type="url" name="Attribute.#index#.Value" value="#myValueArray[i]#"/>
					</cfif>
			<cfset index = index + 1/>
            </cfloop>


            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="DomainName" value="#Arguments.domainName#"/>
            <cfhttpparam type="url" name="ItemName" value="#Arguments.itemName#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.dbVersion#"/>
        </cfhttp>
        
        
        <cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
            <cfreturn XmlParse(CFHTTP.FileContent).PutAttributesResponse.ResponseMetadata.BoxUsage.XmlText/>
    	</cfif>
    </cffunction>
        





	<cffunction name="deleteAttributes" output="true" returntype="string">
        <cfargument name="domainName" type="string" required="true"/>
        <cfargument name="itemName" type="string" required="true"/>
        <cfargument name="attributeNameList" type="string" required="false"/>
        <cfargument name="attributeValueList" type="string" required="false"/>

        <cfset var Function = StructNew()/>
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfif IsDefined("Arguments.attributeNameList")>
			<cfset myNameArray = ListToArray(attributeNameList, ",", "true")>
        	<cfset myValueArray = ListToArray(attributeValueList, ",", "true")>
			<cfset index=1/>
            <cfset attributeNameValuePairs=""/>
            <cfloop from="1" to="#ArrayLen(myNameArray)#" index="i">
                <cfif #myValueArray[i]# eq ""><cfelse>
                    <cfset attributeNameValuePairs = ListAppend(attributeNameValuePairs, "Attribute.#index#.Name=#myNameArray[i]#Attribute.#index#.Value=#myValueArray[i]#")/>
                </cfif>
                <cfset index = index + 1/>
            </cfloop>
            <cfset function.attributeNameValuePairs = ListChangeDelims(Replace(attributeNameValuePairs, "=", "", "All"), "")>
        <cfelse>
        	<cfset function.attributeNameValuePairs = "">
        </cfif>
        
        <cfset Function.fixedData = function.attributeNameValuePairs &
									"ActionDeleteAttributes" &
									"AWSAccessKeyId#This.awsAccessKeyId#" &
									"DomainName#Arguments.domainName#" &
									"ItemName#Arguments.itemName#" &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.dbVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="DeleteAttributes"/>

           <cfif IsDefined("Arguments.attributeNameList")>
			   <cfset index=1/>
                <cfloop from="1" to="#ArrayLen(myNameArray)#" index="i">
                    <cfif #myValueArray[i]# eq ""><cfelse>
                        <cfhttpparam type="url" name="Attribute.#index#.Name" value="#myNameArray[i]#"/>
                        <cfhttpparam type="url" name="Attribute.#index#.Value" value="#myValueArray[i]#"/>
                    </cfif>
                <cfset index = index + 1/>
                </cfloop>
            </cfif>

            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="DomainName" value="#Arguments.domainName#"/>
            <cfhttpparam type="url" name="ItemName" value="#Arguments.itemName#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.dbVersion#"/>
        </cfhttp>
        
        <cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
            <cfreturn XmlParse(CFHTTP.FileContent).DeleteAttributesResponse.ResponseMetadata.BoxUsage.XmlText/>
    	</cfif>
    </cffunction>






    <cffunction name="getAttributes" output="true" returntype="array">
    	<cfargument name="domainName" type="string" required="true"/>
        <cfargument name="itemName" type="string" required="true"/>
        <cfargument name="attributeName" type="string" required="false"/>
        
        <cfset var Function = StructNew()/>
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset Function.domainNamePair = "DomainName#Arguments.domainName#"/>
        <cfset Function.itemNamePair = "ItemName#Arguments.itemName#"/>
        
        <cfif IsDefined("Arguments.attributeName")>
            <cfset Function.attributeNamePair = "AttributeName#Arguments.attributeName#"/>
        <cfelse>
            <cfset Function.attributeNamePair = ""/>
        </cfif>
		
		<cfset Function.fixedData = "ActionGetAttributes" &
									Function.attributeNamePair &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    Function.domainNamePair &
									Function.itemNamePair &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.dbVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="GetAttributes"/>
            <cfif IsDefined("Arguments.attributeNamePair")>
                <cfhttpparam type="url" name="AttributeName" value="#Arguments.attributeName#"/>
            </cfif>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="DomainName" value="#Arguments.domainName#"/>
            <cfhttpparam type="url" name="ItemName" value="#Arguments.itemName#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.dbVersion#"/>
        </cfhttp>
        

		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
            <cfset Function.listAttributes = XmlSearch(CFHTTP.FileContent, "//:Attribute")/>
            
			<cfset Function.attributes = arrayNew(1)/>
            
            <cfloop index="i" from="1" to="#ArrayLen(Function.listAttributes)#">
            	<cfset Function.attribute = StructNew()/>
                <cfset Function.attribute.Name = Function.listAttributes[i].Name.XmlText/>
                <cfset Function.attribute.Value = Function.listAttributes[i].Value.XmlText/>
                <cfset Function.attributes[i] = Function.attribute/>
            </cfloop>

            <cfreturn Function.attributes/>
        </cfif>
    </cffunction>




	<cffunction name="Query" output="true" access="remote" returntype="array">
    	<cfargument name="domainName" type="string" required="true"/>
        <cfargument name="queryExpression" type="string" required="false"/>
        <cfargument name="maxNumberOfItems" type="string" required="false"/>
        <cfargument name="nextToken" type="string" required="false"/>
       

        <cfset var Function = StructNew()/>
        <cfset Function.dateTimeString = zuluDateTimeFormat(Now())/>
        
        <cfset Function.domainName = "DomainName#Arguments.domainName#"/>        
	
        <cfif IsDefined("Arguments.maxNumberOfItems")>
            <cfset Function.maxNumberOfItemsPair = "MaxNumberOfItems#Arguments.maxNumberOfItems#"/>
        <cfelse>
            <cfset Function.maxNumberOfItemsPair = ""/>
        </cfif>


        <cfif IsDefined("Arguments.nextToken")>
            <cfset Function.nextTokenPair = "NextToken#Arguments.nextToken#"/>
        <cfelse>
            <cfset Function.nextTokenPair = ""/>
        </cfif>


        <cfif IsDefined("Arguments.queryExpression")>
            <cfset Function.queryExpressionPair = "QueryExpression#Arguments.queryExpression#"/>
        <cfelse>
            <cfset Function.queryExpressionPair = ""/>
        </cfif>


		<cfset Function.fixedData = "ActionQuery" &
                                    "AWSAccessKeyId#This.awsAccessKeyId#" &
                                    "DomainName#Arguments.domainName#" &
									Function.maxNumberOfItemsPair &
									Function.nextTokenPair &
									Function.queryExpressionPair &
                                    "SignatureVersion1" &
                                    "Timestamp#Function.dateTimeString#" &
                                    "Version#This.dbVersion#"/>
        
        <cfset Function.signature = createSignature(Function.fixedData)/>
        
        <cfhttp method="GET" url="#This.serviceUrl#" charset="UTF-8">
            <cfhttpparam type="url" name="Action" value="Query"/>
            <cfif IsDefined("Arguments.maxNumberOfItems")>
                <cfhttpparam type="url" name="MaxNumberOfItems" value="#Arguments.maxNumberOfItems#"/>
            </cfif>
            <cfif IsDefined("Arguments.nextToken")>
                <cfhttpparam type="url" name="NextToken" value="#Arguments.nextToken#"/>
            </cfif>
            <cfif IsDefined("Arguments.queryExpression")>
                <cfhttpparam type="url" name="QueryExpression" value="#Arguments.queryExpression#"/>
            </cfif>
            <cfhttpparam type="url" name="AWSAccessKeyId" value="#This.awsAccessKeyId#"/>
            <cfhttpparam type="url" name="DomainName" value="#Arguments.domainName#"/>
            <cfhttpparam type="url" name="Signature" value="#Function.signature#"/>
            <cfhttpparam type="url" name="SignatureVersion" value="1"/>
            <cfhttpparam type="url" name="Timestamp" value="#Function.dateTimeString#"/>
            <cfhttpparam type="url" name="Version" value="#This.dbVersion#"/>
        </cfhttp>
        

		<cfif CFHTTP.ResponseHeader.Status_Code neq 200>
            <cfinvoke method="handleErrors"
                content="#CFHTTP.FileContent#"
            />
        <cfelse>
            <cfset Function.listItems = XmlSearch(CFHTTP.FileContent, "//:ItemName")/>
            
			<cfset Function.items = arrayNew(1)/>
            
            <cfloop index="i" from="1" to="#ArrayLen(Function.listItems)#">
            	<cfset Function.item = StructNew()/>
                <cfset Function.item.ItemName = Function.listItems[i].XmlText/>
                <cfset Function.items[i] = Function.item/>
            </cfloop>

            <cfreturn Function.items/>
        </cfif>
    </cffunction>
    
	<cfscript>
        /**
         * Sorts an array of structures based on a key in the structures.
         * 
         * @param aofS 	 Array of structures. 
         * @param key 	 Key to sort by. 
         * @param sortOrder 	 Order to sort by, asc or desc. 
         * @param sortType 	 Text, textnocase, or numeric. 
         * @param delim 	 Delimiter used for temporary data storage. Must not exist in data. Defaults to a period. 
         * @return Returns a sorted array. 
         * @author Nathan Dintenfass (&#110;&#97;&#116;&#104;&#97;&#110;&#64;&#99;&#104;&#97;&#110;&#103;&#101;&#109;&#101;&#100;&#105;&#97;&#46;&#99;&#111;&#109;) 
         * @version 1, December 10, 2001 
         */
        function arrayOfStructsSort(aOfS,key){
                //by default we'll use an ascending sort
                var sortOrder = "asc";		
                //by default, we'll use a textnocase sort
                var sortType = "textnocase";
                //by default, use ascii character 30 as the delim
                var delim = ".";
                //make an array to hold the sort stuff
                var sortArray = arraynew(1);
                //make an array to return
                var returnArray = arraynew(1);
                //grab the number of elements in the array (used in the loops)
                var count = arrayLen(aOfS);
                //make a variable to use in the loop
                var ii = 1;
                //if there is a 3rd argument, set the sortOrder
                if(arraylen(arguments) GT 2)
                    sortOrder = arguments[3];
                //if there is a 4th argument, set the sortType
                if(arraylen(arguments) GT 3)
                    sortType = arguments[4];
                //if there is a 5th argument, set the delim
                if(arraylen(arguments) GT 4)
                    delim = arguments[5];
                //loop over the array of structs, building the sortArray
                for(ii = 1; ii lte count; ii = ii + 1)
                    sortArray[ii] = aOfS[ii][key] & delim & ii;
                //now sort the array
                arraySort(sortArray,sortType,sortOrder);
                //now build the return array
                for(ii = 1; ii lte count; ii = ii + 1)
                    returnArray[ii] = aOfS[listLast(sortArray[ii],delim)];
                //return the array
                return returnArray;
        }
        </cfscript>


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
            
            <cfset Function.content = XmlSearch(Arguments.content, "//Response/Errors/Error")/>
            <cfset Function.errorCode = Function.content[1].Code.XmlText/>
            <cfset Function.errorMessage = Function.content[1].Message.XmlText/>
            
            <cfthrow type="#Function.errorCode#" 
                message="#Function.errorCode#" 
                detail="#Function.errorMessage#"
            />
        </cfif>
    </cffunction>

</cfcomponent>

