<!--- hmac.cfm custom tag converted to cfc by Sam Curren --->
<cfcomponent output="false">

	<!---
	Programmer: Tim McCarthy (tim@timmcc.com)
	Date: February, 2003
	Description:
		Implements HMAC, a mechanism for message authentication using hash functions
		as specified in RFC 2104 (http://www.ietf.org/rfc/rfc2104.txt).  HMAC requires
		a hash function H and a secret key K and is computed as follows:
			H(K XOR opad, H(K XOR ipad, data)), where
				ipad = the byte 0x36 repeated 64 times
				opad = the byte 0x5c repeated 64 times
				data = the data to be authenticated
	Required parameters: data, key
	Optional parameters:
		data_format: hex = data is in hexadecimal format (default is ASCII text)
		key_format: hex = key is in hexadecimal format (default is ASCII text)
		hash_function: md5, sha1, sha256, or ripemd160 (default is md5)
		output_bits: truncate output to leftmost bits indicated (default is all)
	Nested custom tags: md5.cfm, ripemd_160.cfm, sha_1.cfm, sha_256.cfm
	Example syntax: <cf_hmac data="what do ya want for nothing?" key="Jefe">
	Output variable: caller.digest
	Note:
		This version accepts input in both ASCII text and hexadecimal formats.
		Previous versions did not accept input in hexadecimal format.
	--->
	<cffunction name="hmac">
		<cfargument name="data_format" default=""/>
		<cfargument name="key_format" default=""/>
		<cfargument name="hash_function" default="md5"/>
		<cfargument name="output_bits" default="256"/>
		
		<!--- convert data to ASCII binary-coded form --->
		<CFIF arguments.data_format EQ "hex">
			<CFSET hex_data = attributes.data/>
		<CFELSE>
			<CFSET hex_data = "">
			<CFLOOP index="i" from="1" to="#Len(arguments.data)#">
				<CFSET hex_data = hex_data & Right("0"&FormatBaseN(Asc(Mid(arguments.data,i,1)),16),2)>
			</CFLOOP>
		</CFIF>
		
		<!--- convert key to ASCII binary-coded form --->
		<CFIF arguments.key_format EQ "hex">
			<CFSET hex_key = arguments.key>
		<CFELSE>
			<CFSET hex_key = "">
			<CFLOOP index="i" from="1" to="#Len(arguments.key)#">
				<CFSET hex_key = hex_key & Right("0"&FormatBaseN(Asc(Mid(arguments.key,i,1)),16),2)>
			</CFLOOP>
		</CFIF>
		
		<CFSET key_len = Len(hex_key)/2>
		
		<!--- if key longer than 64 bytes, use hash of key as key --->
		<CFIF key_len GT 64>
			<CFSWITCH expression="#arguments.hash_function#">
				<CFCASE value="md5">
					<cfinvoke method="md5" msg="#hex_key#" format="hex" returnvariable="msg_digest"/>
				</CFCASE>
				<CFCASE value="sha1">
					<cfinvoke method="sha_1" msg="#hex_key#" format="hex" returnvariable="msg_digest"/>
				</CFCASE>
				<CFCASE value="sha256">
					<cfinvoke method="sha_256" msg="#hex_key#" format="hex" returnvariable="msg_digest"/>
				</CFCASE>
				<CFCASE value="ripemd160">
					<cfinvoke method="ripemd_160" msg="#hex_key#" format="hex" returnvariable="msg_digest"/>
				</CFCASE>
			</CFSWITCH>
			<CFSET hex_key = msg_digest>
			<CFSET key_len = Len(hex_key)/2>
		</CFIF>
		
		<CFSET key_ipad = "">
		<CFSET key_opad = "">
		<CFLOOP index="i" from="1" to="#key_len#">
			<CFSET key_ipad = key_ipad & Right("0"&FormatBaseN(BitXor(InputBaseN(Mid(hex_key,2*i-1,2),16),InputBaseN("36",16)),16),2)>
			<CFSET key_opad = key_opad & Right("0"&FormatBaseN(BitXor(InputBaseN(Mid(hex_key,2*i-1,2),16),InputBaseN("5c",16)),16),2)>
		</CFLOOP>
		<CFSET key_ipad = key_ipad & RepeatString("36",64-key_len)>
		<CFSET key_opad = key_opad & RepeatString("5c",64-key_len)>
		
		<CFSWITCH expression="#arguments.hash_function#">
			<CFCASE value="md5">
				<cfinvoke method="md5" msg="#key_ipad##hex_data#" format="hex" returnvariable="msg_digest"/>
				<cfinvoke method="md5" msg="#key_opad##msg_digest#" format="hex" returnvariable="msg_digest"/>
			</CFCASE>
			<CFCASE value="sha1">
				<cfinvoke method="sha_1" msg="#key_ipad##hex_data#" format="hex" returnvariable="msg_digest"/>
				<cfinvoke method="sha_1" msg="#key_opad##msg_digest#" format="hex" returnvariable="msg_digest"/>
			</CFCASE>
			<CFCASE value="sha256">
				<cfinvoke method="sha_256" msg="#key_ipad##hex_data#" format="hex" returnvariable="msg_digest"/>
				<cfinvoke method="sha_256" msg="#key_opad##msg_digest#" format="hex" returnvariable="msg_digest"/>
			</CFCASE>
			<CFCASE value="ripemd160">
				<cfinvoke method="ripemd_160" msg="#key_ipad##hex_data#" format="hex" returnvariable="msg_digest"/>
				<cfinvoke method="ripemd_160" msg="#key_opad##msg_digest#" format="hex" returnvariable="msg_digest"/>
			</CFCASE>
		</CFSWITCH>
		
		<!--- <CFSET caller.digest = Left(msg_digest,attributes.output_bits/4)> --->
		<cfreturn Left(msg_digest,arguments.output_bits/4)/>
	</cffunction>

	<!---
	Programmer: Tim McCarthy (tim@timmcc.com)
	Date: February, 2003
	Description:
		Produces a 128-bit condensed representation of a message (attributes.msg) called
		a message digest (caller.msg_digest) using the RSA MD5 message-digest algorithm
		as specified in RFC 1321 (http://www.ietf.org/rfc/rfc1321.txt)
	Required parameter: msg
	Optional parameter: format="hex" (hexadecimal, default is ASCII text)
	Example syntax: <cf_md5 msg="abcdefghijklmnopqrstuvwxyz">
	Output variable: caller.msg_digest
	Note:
		This version accepts input in both ASCII text and hexadecimal formats.
		Previous versions did not accept input in hexadecimal format.
	--->
	<cffunction name="md5" output="false">
		<cfargument name="msg" required="true"/>
		<cfargument name="format" default=""/>
		<!--- default value of optional parameter
		<CFPARAM name="attributes.format" default=""> --->
		
		<!--- convert the msg to ASCII binary-coded form --->
		<CFIF arguments.format EQ "hex">
			<CFSET hex_msg = arguments.msg>
		<CFELSE>
			<CFSET hex_msg = "">
			<CFLOOP index="i" from="1" to="#Len(arguments.msg)#">
				<CFSET hex_msg = hex_msg & Right("0"&FormatBaseN(Asc(Mid(arguments.msg,i,1)),16),2)>
			</CFLOOP>
		</CFIF>
		
		<!--- compute the msg length in bits --->
		<CFSET hex_msg_len = Right(RepeatString("0",15)&FormatBaseN(4*Len(hex_msg),16),16)>
		<CFSET temp = "">
		<CFLOOP index="i" from="1" to="8">
			<CFSET temp = temp & Mid(hex_msg_len,-2*(i-8)+1,2)>
		</CFLOOP>
		<CFSET hex_msg_len = temp>
		
		<!--- pad the msg to make it a multiple of 512 bits long --->
		<CFSET padded_hex_msg = hex_msg & "80" & RepeatString("0",128-((Len(hex_msg)+2+16) Mod 128)) & hex_msg_len>
		
		<!--- initialize MD buffer --->
		<CFSET h = ArrayNew(1)>
		<CFSET h[1] = InputBaseN("0x67452301",16)>
		<CFSET h[2] = InputBaseN("0xefcdab89",16)>
		<CFSET h[3] = InputBaseN("0x98badcfe",16)>
		<CFSET h[4] = InputBaseN("0x10325476",16)>
		
		<CFSET var = ArrayNew(1)>
		<CFSET var[1] = "a">
		<CFSET var[2] = "b">
		<CFSET var[3] = "c">
		<CFSET var[4] = "d">
		
		<CFSET m = ArrayNew(1)>
		
		<CFSET t = ArrayNew(1)>
		<CFSET k = ArrayNew(1)>
		<CFSET s = ArrayNew(1)>
		<CFLOOP index="i" from="1" to="64">
			<CFSET t[i] = Int(2^32*abs(sin(i)))>
			<CFIF i LE 16>
				<CFIF i EQ 1>
					<CFSET k[i] = 0>
				<CFELSE>
					<CFSET k[i] = k[i-1] + 1>
				</CFIF>
				<CFSET s[i] = 5*((i-1) MOD 4) + 7>
			<CFELSEIF i LE 32>
				<CFIF i EQ 17>
					<CFSET k[i] = 1>
				<CFELSE>
					<CFSET k[i] = (k[i-1]+5) MOD 16>
				</CFIF>
				<CFSET s[i] = 0.5*((i-1) MOD 4)*((i-1) MOD 4) + 3.5*((i-1) MOD 4) + 5>
			<CFELSEIF i LE 48>
				<CFIF i EQ 33>
					<CFSET k[i] = 5>
				<CFELSE>
					<CFSET k[i] = (k[i-1]+3) MOD 16>
				</CFIF>
				<CFSET s[i] = 6*((i-1) MOD 4) + ((i-1) MOD 2) + 4>
			<CFELSE>
				<CFIF i EQ 49>
					<CFSET k[i] = 0>
				<CFELSE>
					<CFSET k[i] = (k[i-1]+7) MOD 16>
				</CFIF>
				<CFSET s[i] = 0.5*((i-1) MOD 4)*((i-1) MOD 4) + 3.5*((i-1) MOD 4) + 6>
			</CFIF>
		</CFLOOP>
		
		<!--- process the msg 512 bits at a time --->
		<CFLOOP index="n" from="1" to="#Evaluate(Len(padded_hex_msg)/128)#">
			
			<CFSET a = h[1]>
			<CFSET b = h[2]>
			<CFSET c = h[3]>
			<CFSET d = h[4]>
			
			<CFSET msg_block = Mid(padded_hex_msg,128*(n-1)+1,128)>
			<CFLOOP index="i" from="1" to="16">
				<CFSET sub_block = "">
				<CFLOOP index="j" from="1" to="4">
					<CFSET sub_block = sub_block & Mid(msg_block,8*i-2*j+1,2)>
				</CFLOOP>
				<CFSET m[i] = InputBaseN(sub_block,16)>
			</CFLOOP>
			
			<CFLOOP index="i" from="1" to="64">
				
				<CFIF i LE 16>
					<CFSET f = BitOr(BitAnd(Evaluate(var[2]),Evaluate(var[3])),BitAnd(BitNot(Evaluate(var[2])),Evaluate(var[4])))>
				<CFELSEIF i LE 32>
					<CFSET f = BitOr(BitAnd(Evaluate(var[2]),Evaluate(var[4])),BitAnd(Evaluate(var[3]),BitNot(Evaluate(var[4]))))>
				<CFELSEIF i LE 48>
					<CFSET f = BitXor(BitXor(Evaluate(var[2]),Evaluate(var[3])),Evaluate(var[4]))>
				<CFELSE>
					<CFSET f = BitXor(Evaluate(var[3]),BitOr(Evaluate(var[2]),BitNot(Evaluate(var[4]))))>
				</CFIF>
				
				<CFSET temp = Evaluate(var[1]) + f + m[k[i]+1] + t[i]>
				<CFLOOP condition="(temp LT -2^31) OR (temp GE 2^31)">
					<CFSET temp = temp - Sgn(temp)*2^32>
				</CFLOOP>
				<CFSET temp = Evaluate(var[2]) + BitOr(BitSHLN(temp,s[i]),BitSHRN(temp,32-s[i]))>
				<CFLOOP condition="(temp LT -2^31) OR (temp GE 2^31)">
					<CFSET temp = temp - Sgn(temp)*2^32>
				</CFLOOP>
				<CFSET temp = SetVariable(var[1],temp)>
				
				<CFSET temp = var[4]>
				<CFSET var[4] = var[3]>
				<CFSET var[3] = var[2]>
				<CFSET var[2] = var[1]>
				<CFSET var[1] = temp>
				
			</CFLOOP>
			
			<CFSET h[1] = h[1] + a>
			<CFSET h[2] = h[2] + b>
			<CFSET h[3] = h[3] + c>
			<CFSET h[4] = h[4] + d>
			
			<CFLOOP index="i" from="1" to="4">
				<CFLOOP condition="(h[i] LT -2^31) OR (h[i] GE 2^31)">
					<CFSET h[i] = h[i] - Sgn(h[i])*2^32>
				</CFLOOP>
			</CFLOOP>
			
		</CFLOOP>
		
		<CFLOOP index="i" from="1" to="4">
			<CFSET h[i] = Right(RepeatString("0",7)&UCase(FormatBaseN(h[i],16)),8)>
		</CFLOOP>
		
		<CFLOOP index="i" from="1" to="4">
			<CFSET temp = "">
			<CFLOOP index="j" from="1" to="4">
				<CFSET temp = temp & Mid(h[i],-2*(j-4)+1,2)>
			</CFLOOP>
			<CFSET h[i] = temp>
		</CFLOOP>
		
		<!--- <CFSET caller.msg_digest = h[1] & h[2] & h[3] & h[4]> --->
		<cfreturn h[1] & h[2] & h[3] & h[4]/>
	</cffunction>

	<!---
	Programmer: Tim McCarthy (tim@timmcc.com)
	Date: February, 2003
	Description:
		Produces a 160-bit condensed representation of a message (attributes.msg) called
		a message digest (caller.msg_digest) using the Secure Hash Algorithm (SHA-1)
		as specified in FIPS PUB 180-1 (http://www.itl.nist.gov/fipspubs/fip180-1.htm)
	Required parameter: msg
	Optional parameter: format="hex" (hexadecimal, default is ASCII text)
	Example syntax: <cf_sha_1 msg="abcdefghijklmnopqrstuvwxyz">
	Output variable: caller.msg_digest
	Note:
		This version accepts input in both ASCII text and hexadecimal formats.
		Previous versions did not accept input in hexadecimal format.
	--->
	<cffunction name="sha_1" output="false">
		<cfargument name="msg" required="true"/>
		<cfargument name="format" default=""/>
		<!--- default value of optional parameter
		<CFPARAM name="attributes.format" default=""> --->
		
		<!--- convert the msg to ASCII binary-coded form --->
		<CFIF arguments.format EQ "hex">
			<CFSET hex_msg = arguments.msg>
		<CFELSE>
			<CFSET hex_msg = "">
			<CFLOOP index="i" from="1" to="#Len(arguments.msg)#">
				<CFSET hex_msg = hex_msg & Right("0"&FormatBaseN(Asc(Mid(arguments.msg,i,1)),16),2)>
			</CFLOOP>
		</CFIF>
		
		<!--- compute the msg length in bits --->
		<CFSET hex_msg_len = FormatBaseN(4*Len(hex_msg),16)>
		
		<!--- pad the msg to make it a multiple of 512 bits long --->
		<CFSET padded_hex_msg = hex_msg & "80" & RepeatString("0",128-((Len(hex_msg)+2+16) Mod 128)) & RepeatString("0",16-Len(hex_msg_len)) & hex_msg_len>
		
		<!--- initialize the buffers --->
		<CFSET h = ArrayNew(1)>
		<CFSET h[1] = InputBaseN("0x67452301",16)>
		<CFSET h[2] = InputBaseN("0xefcdab89",16)>
		<CFSET h[3] = InputBaseN("0x98badcfe",16)>
		<CFSET h[4] = InputBaseN("0x10325476",16)>
		<CFSET h[5] = InputBaseN("0xc3d2e1f0",16)>
		
		<CFSET w = ArrayNew(1)>
		
		<!--- process the msg 512 bits at a time --->
		<CFLOOP index="n" from="1" to="#Evaluate(Len(padded_hex_msg)/128)#">
			
			<CFSET msg_block = Mid(padded_hex_msg,128*(n-1)+1,128)>
			
			<CFSET a = h[1]>
			<CFSET b = h[2]>
			<CFSET c = h[3]>
			<CFSET d = h[4]>
			<CFSET e = h[5]>
			
			<CFLOOP index="t" from="0" to="79">
				
				<!--- nonlinear functions and constants --->
				<CFIF t LE 19>
					<CFSET f = BitOr(BitAnd(b,c),BitAnd(BitNot(b),d))>
					<CFSET k = InputBaseN("0x5a827999",16)>
				<CFELSEIF t LE 39>
					<CFSET f = BitXor(BitXor(b,c),d)>
					<CFSET k = InputBaseN("0x6ed9eba1",16)>
				<CFELSEIF t LE 59>
					<CFSET f = BitOr(BitOr(BitAnd(b,c),BitAnd(b,d)),BitAnd(c,d))>
					<CFSET k = InputBaseN("0x8f1bbcdc",16)>
				<CFELSE>
					<CFSET f = BitXor(BitXor(b,c),d)>
					<CFSET k = InputBaseN("0xca62c1d6",16)>
				</CFIF>
				
				<!--- transform the msg block from 16 32-bit words to 80 32-bit words --->
				<CFIF t LE 15>
					<CFSET w[t+1] = InputBaseN(Mid(msg_block,8*t+1,8),16)>
				<CFELSE>
					<CFSET num = BitXor(BitXor(BitXor(w[t-3+1],w[t-8+1]),w[t-14+1]),w[t-16+1])>
					<CFSET w[t+1] = BitOr(BitSHLN(num,1),BitSHRN(num,32-1))>
				</CFIF>
				
				<CFSET temp = BitOr(BitSHLN(a,5),BitSHRN(a,32-5)) + f + e + w[t+1] + k>
				<CFSET e = d>
				<CFSET d = c>
				<CFSET c = BitOr(BitSHLN(b,30),BitSHRN(b,32-30))>
				<CFSET b = a>
				<CFSET a = temp>
				
				<CFSET num = a>
				<CFLOOP condition="(num LT -2^31) OR (num GE 2^31)">
					<CFSET num = num - Sgn(num)*2^32>
				</CFLOOP>
				<CFSET a = num>
				
			</CFLOOP>
			
			<CFSET h[1] = h[1] + a>
			<CFSET h[2] = h[2] + b>
			<CFSET h[3] = h[3] + c>
			<CFSET h[4] = h[4] + d>
			<CFSET h[5] = h[5] + e>
			
			<CFLOOP index="i" from="1" to="5">
				<CFLOOP condition="(h[i] LT -2^31) OR (h[i] GE 2^31)">
					<CFSET h[i] = h[i] - Sgn(h[i])*2^32>
				</CFLOOP>
			</CFLOOP>
			
		</CFLOOP>
		
		<CFLOOP index="i" from="1" to="5">
			<CFSET h[i] = RepeatString("0",8-Len(FormatBaseN(h[i],16))) & UCase(FormatBaseN(h[i],16))>
		</CFLOOP>
		
		<!--- <CFSET caller.msg_digest = h[1] & h[2] & h[3] & h[4] & h[5]>	 --->
		<cfreturn h[1] & h[2] & h[3] & h[4] & h[5]/>
	</cffunction>

	<!---
	Programmer: Tim McCarthy (tim@timmcc.com)
	Date: February, 2003
	Description:
		Produces a 256-bit condensed representation of a message (attributes.msg) called
		a message digest (caller.msg_digest) using the Secure Hash Algorithm (SHA-256) as
		specified in FIPS PUB 180-2 (http://csrc.nist.gov/publications/fips/fips180-2/fips180-2.pdf)
		On August 26, 2002, NIST announced the approval of FIPS 180-2, Secure Hash Standard,
		which contains the specifications for the Secure Hash Algorithms (SHA-1, SHA-256, SHA-384,
		and SHA-256) with several examples.  This standard became effective on February 1, 2003.
	Required parameter: msg
	Optional parameter: format="hex" (hexadecimal, default is ASCII text)
	Example syntax: <cf_sha_256 msg="abcdefghijklmnopqrstuvwxyz">
	Output variable: caller.msg_digest
	Note:
		This version accepts input in both ASCII text and hexadecimal formats.
		Previous versions did not accept input in hexadecimal format.
	--->
	<cffunction name="sha_256" output="false">
		<cfargument name="msg" required="true"/>
		<cfargument name="format" default=""/>
		<!--- default value of optional parameter
		<CFPARAM name="attributes.format" default=""> --->
		
		<!--- convert the msg to ASCII binary-coded form --->
		<CFIF arguments.format EQ "hex">
			<CFSET hex_msg = arguments.msg>
		<CFELSE>
			<CFSET hex_msg = "">
			<CFLOOP index="i" from="1" to="#Len(arguments.msg)#">
				<CFSET hex_msg = hex_msg & Right("0"&FormatBaseN(Asc(Mid(arguments.msg,i,1)),16),2)>
			</CFLOOP>
		</CFIF>
		
		<!--- compute the msg length in bits --->
		<CFSET hex_msg_len = FormatBaseN(4*Len(hex_msg),16)>
		
		<!--- pad the msg to make it a multiple of 512 bits long --->
		<CFSET padded_hex_msg = hex_msg & "80" & RepeatString("0",128-((Len(hex_msg)+2+16) Mod 128)) & RepeatString("0",16-Len(hex_msg_len)) & hex_msg_len>
		
		<!--- first sixty-four prime numbers --->
		<CFSET prime = ArrayNew(1)>
		<CFSET prime[1] = 2>
		<CFSET prime[2] = 3>
		<CFSET prime[3] = 5>
		<CFSET prime[4] = 7>
		<CFSET prime[5] = 11>
		<CFSET prime[6] = 13>
		<CFSET prime[7] = 17>
		<CFSET prime[8] = 19>
		<CFSET prime[9] = 23>
		<CFSET prime[10] = 29>
		<CFSET prime[11] = 31>
		<CFSET prime[12] = 37>
		<CFSET prime[13] = 41>
		<CFSET prime[14] = 43>
		<CFSET prime[15] = 47>
		<CFSET prime[16] = 53>
		<CFSET prime[17] = 59>
		<CFSET prime[18] = 61>
		<CFSET prime[19] = 67>
		<CFSET prime[20] = 71>
		<CFSET prime[21] = 73>
		<CFSET prime[22] = 79>
		<CFSET prime[23] = 83>
		<CFSET prime[24] = 89>
		<CFSET prime[25] = 97>
		<CFSET prime[26] = 101>
		<CFSET prime[27] = 103>
		<CFSET prime[28] = 107>
		<CFSET prime[29] = 109>
		<CFSET prime[30] = 113>
		<CFSET prime[31] = 127>
		<CFSET prime[32] = 131>
		<CFSET prime[33] = 137>
		<CFSET prime[34] = 139>
		<CFSET prime[35] = 149>
		<CFSET prime[36] = 151>
		<CFSET prime[37] = 157>
		<CFSET prime[38] = 163>
		<CFSET prime[39] = 167>
		<CFSET prime[40] = 173>
		<CFSET prime[41] = 179>
		<CFSET prime[42] = 181>
		<CFSET prime[43] = 191>
		<CFSET prime[44] = 193>
		<CFSET prime[45] = 197>
		<CFSET prime[46] = 199>
		<CFSET prime[47] = 211>
		<CFSET prime[48] = 223>
		<CFSET prime[49] = 227>
		<CFSET prime[50] = 229>
		<CFSET prime[51] = 233>
		<CFSET prime[52] = 239>
		<CFSET prime[53] = 241>
		<CFSET prime[54] = 251>
		<CFSET prime[55] = 257>
		<CFSET prime[56] = 263>
		<CFSET prime[57] = 269>
		<CFSET prime[58] = 271>
		<CFSET prime[59] = 277>
		<CFSET prime[60] = 281>
		<CFSET prime[61] = 283>
		<CFSET prime[62] = 293>
		<CFSET prime[63] = 307>
		<CFSET prime[64] = 311>
		
		<!--- constants --->
		<CFSET k = ArrayNew(1)>
		<CFLOOP index="i" from="1" to="64">
			<CFSET k[i] = Int(prime[i]^(1/3)*2^32)>
		</CFLOOP>
		
		<!--- initial hash values --->
		<CFSET h = ArrayNew(1)>
		<CFLOOP index="i" from="1" to="8">
			<CFSET h[i] = Int(Sqr(prime[i])*2^32)>
			<CFLOOP condition="(h[i] LT -2^31) OR (h[i] GE 2^31)">
				<CFSET h[i] = h[i] - Sgn(h[i])*2^32>
			</CFLOOP>
		</CFLOOP>
		
		<CFSET w = ArrayNew(1)>
		
		<!--- process the msg 512 bits at a time --->
		<CFLOOP index="n" from="1" to="#Evaluate(Len(padded_hex_msg)/128)#">
			
			<!--- initialize the eight working variables --->
			<CFSET a = h[1]>
			<CFSET b = h[2]>
			<CFSET c = h[3]>
			<CFSET d = h[4]>
			<CFSET e = h[5]>
			<CFSET f = h[6]>
			<CFSET g = h[7]>
			<CFSET hh = h[8]>
			
			<!--- nonlinear functions and message schedule --->
			<CFSET msg_block = Mid(padded_hex_msg,128*(n-1)+1,128)>
			<CFLOOP index="t" from="0" to="63">
				
				<CFIF t LE 15>
					<CFSET w[t+1] = InputBaseN(Mid(msg_block,8*t+1,8),16)>
				<CFELSE>
					<CFSET smsig0 = BitXor(BitXor(BitOr(BitSHRN(w[t-15+1],7),BitSHLN(w[t-15+1],32-7)),BitOr(BitSHRN(w[t-15+1],18),BitSHLN(w[t-15+1],32-18))),BitSHRN(w[t-15+1],3))>
					<CFSET smsig1 = BitXor(BitXor(BitOr(BitSHRN(w[t-2+1],17),BitSHLN(w[t-2+1],32-17)),BitOr(BitSHRN(w[t-2+1],19),BitSHLN(w[t-2+1],32-19))),BitSHRN(w[t-2+1],10))>
					<CFSET w[t+1] = smsig1 + w[t-7+1] + smsig0 + w[t-16+1]>
				</CFIF>
				<CFLOOP condition="(w[t+1] LT -2^31) OR (w[t+1] GE 2^31)">
					<CFSET w[t+1] = w[t+1] - Sgn(w[t+1])*2^32>
				</CFLOOP>
				
				<CFSET bgsig0 = BitXor(BitXor(BitOr(BitSHRN(a,2),BitSHLN(a,32-2)),BitOr(BitSHRN(a,13),BitSHLN(a,32-13))),BitOr(BitSHRN(a,22),BitSHLN(a,32-22)))>
				<CFSET bgsig1 = BitXor(BitXor(BitOr(BitSHRN(e,6),BitSHLN(e,32-6)),BitOr(BitSHRN(e,11),BitSHLN(e,32-11))),BitOr(BitSHRN(e,25),BitSHLN(e,32-25)))>
				<CFSET ch = BitXor(BitAnd(e,f),BitAnd(BitNot(e),g))>
				<CFSET maj = BitXor(BitXor(BitAnd(a,b),BitAnd(a,c)),BitAnd(b,c))>
				
				<CFSET t1 = hh + bgsig1 + ch + k[t+1] + w[t+1]>
				<CFSET t2 = bgsig0 + maj>
				<CFSET hh = g>
				<CFSET g = f>
				<CFSET f = e>
				<CFSET e = d + t1>
				<CFSET d = c>
				<CFSET c = b>
				<CFSET b = a>
				<CFSET a = t1 + t2>
				
				<CFLOOP condition="(a LT -2^31) OR (a GE 2^31)">
					<CFSET a = a - Sgn(a)*2^32>
				</CFLOOP>
				<CFLOOP condition="(e LT -2^31) OR (e GE 2^31)">
					<CFSET e = e - Sgn(e)*2^32>
				</CFLOOP>
				
			</CFLOOP>
			
			<CFSET h[1] = h[1] + a>
			<CFSET h[2] = h[2] + b>
			<CFSET h[3] = h[3] + c>
			<CFSET h[4] = h[4] + d>
			<CFSET h[5] = h[5] + e>
			<CFSET h[6] = h[6] + f>
			<CFSET h[7] = h[7] + g>
			<CFSET h[8] = h[8] + hh>
			
			<CFLOOP index="i" from="1" to="8">
				<CFLOOP condition="(h[i] LT -2^31) OR (h[i] GE 2^31)">
					<CFSET h[i] = h[i] - Sgn(h[i])*2^32>
				</CFLOOP>
			</CFLOOP>
			
		</CFLOOP>
		
		<CFLOOP index="i" from="1" to="8">
			<CFSET h[i] = RepeatString("0",8-Len(FormatBaseN(h[i],16))) & UCase(FormatBaseN(h[i],16))>
		</CFLOOP>
		
		<!--- <CFSET caller.msg_digest = h[1] & h[2] & h[3] & h[4] & h[5] & h[6] & h[7] & h[8]> --->
		<cfreturn h[1] & h[2] & h[3] & h[4] & h[5] & h[6] & h[7] & h[8]/>
	</cffunction>

	<!---
	Programmer: Tim McCarthy (tim@timmcc.com)
	Date: February, 2003
	Description:
		Produces a 160-bit condensed representation of a message (attributes.msg) called
		a message digest (caller.msg_digest) using the RIPEMD-160 hash function as
		specified in http://www.esat.kuleuven.ac.be/~bosselae/ripemd160.html
	Required parameter: msg
	Optional parameter: format="hex" (hexadecimal, default is ASCII text)
	Example syntax: <cf_ripemd_160 msg="abcdefghijklmnopqrstuvwxyz">
	Output variable: caller.msg_digest
	Note:
		This version accepts input in both ASCII text and hexadecimal formats.
		Previous versions did not accept input in hexadecimal format.
	--->
	<cffunction name="ripemd_160" output="false">
		<cfargument name="msg" required="true"/>
		<cfargument name="format" default=""/>
		<!--- default value of optional parameter
		<CFPARAM name="attributes.format" default=""> --->
		
		<!--- convert the msg to ASCII binary-coded form --->
		<CFIF arguments.format EQ "hex">
			<CFSET hex_msg = arguments.msg>
		<CFELSE>
			<CFSET hex_msg = "">
			<CFLOOP index="i" from="1" to="#Len(arguments.msg)#">
				<CFSET hex_msg = hex_msg & Right("0"&FormatBaseN(Asc(Mid(arguments.msg,i,1)),16),2)>
			</CFLOOP>
		</CFIF>
		
		<!--- compute the msg length in bits --->
		<CFSET hex_msg_len = Right(RepeatString("0",15)&FormatBaseN(4*Len(hex_msg),16),16)>
		<CFSET temp = "">
		<CFLOOP index="i" from="1" to="8">
			<CFSET temp = temp & Mid(hex_msg_len,-2*(i-8)+1,2)>
		</CFLOOP>
		<CFSET hex_msg_len = temp>
		
		<!--- pad the msg to make it a multiple of 512 bits long --->
		<CFSET padded_hex_msg = hex_msg & "80" & RepeatString("0",128-((Len(hex_msg)+2+16) Mod 128)) & hex_msg_len>
		
		<!--- define permutations --->
		<CFSET rho = ArrayNew(1)>
		<CFSET rho[1] = 7>
		<CFSET rho[2] = 4>
		<CFSET rho[3] = 13>
		<CFSET rho[4] = 1>
		<CFSET rho[5] = 10>
		<CFSET rho[6] = 6>
		<CFSET rho[7] = 15>
		<CFSET rho[8] = 3>
		<CFSET rho[9] = 12>
		<CFSET rho[10] = 0>
		<CFSET rho[11] = 9>
		<CFSET rho[12] = 5>
		<CFSET rho[13] = 2>
		<CFSET rho[14] = 14>
		<CFSET rho[15] = 11>
		<CFSET rho[16] = 8>
		
		<CFSET pi = ArrayNew(1)>
		<CFLOOP index="i" from="1" to="16">
			<CFSET pi[i] = (9*(i-1)+5) Mod 16>
		</CFLOOP>
		
		<!--- define shifts --->
		<CFSET shift = ArrayNew(2)>
		<CFSET shift[1][1] = 11>
		<CFSET shift[1][2] = 14>
		<CFSET shift[1][3] = 15>
		<CFSET shift[1][4] = 12>
		<CFSET shift[1][5] = 5>
		<CFSET shift[1][6] = 8>
		<CFSET shift[1][7] = 7>
		<CFSET shift[1][8] = 9>
		<CFSET shift[1][9] = 11>
		<CFSET shift[1][10] = 13>
		<CFSET shift[1][11] = 14>
		<CFSET shift[1][12] = 15>
		<CFSET shift[1][13] = 6>
		<CFSET shift[1][14] = 7>
		<CFSET shift[1][15] = 9>
		<CFSET shift[1][16] = 8>
		<CFSET shift[2][1] = 12>
		<CFSET shift[2][2] = 13>
		<CFSET shift[2][3] = 11>
		<CFSET shift[2][4] = 15>
		<CFSET shift[2][5] = 6>
		<CFSET shift[2][6] = 9>
		<CFSET shift[2][7] = 9>
		<CFSET shift[2][8] = 7>
		<CFSET shift[2][9] = 12>
		<CFSET shift[2][10] = 15>
		<CFSET shift[2][11] = 11>
		<CFSET shift[2][12] = 13>
		<CFSET shift[2][13] = 7>
		<CFSET shift[2][14] = 8>
		<CFSET shift[2][15] = 7>
		<CFSET shift[2][16] = 7>
		<CFSET shift[3][1] = 13>
		<CFSET shift[3][2] = 15>
		<CFSET shift[3][3] = 14>
		<CFSET shift[3][4] = 11>
		<CFSET shift[3][5] = 7>
		<CFSET shift[3][6] = 7>
		<CFSET shift[3][7] = 6>
		<CFSET shift[3][8] = 8>
		<CFSET shift[3][9] = 13>
		<CFSET shift[3][10] = 14>
		<CFSET shift[3][11] = 13>
		<CFSET shift[3][12] = 12>
		<CFSET shift[3][13] = 5>
		<CFSET shift[3][14] = 5>
		<CFSET shift[3][15] = 6>
		<CFSET shift[3][16] = 9>
		<CFSET shift[4][1] = 14>
		<CFSET shift[4][2] = 11>
		<CFSET shift[4][3] = 12>
		<CFSET shift[4][4] = 14>
		<CFSET shift[4][5] = 8>
		<CFSET shift[4][6] = 6>
		<CFSET shift[4][7] = 5>
		<CFSET shift[4][8] = 5>
		<CFSET shift[4][9] = 15>
		<CFSET shift[4][10] = 12>
		<CFSET shift[4][11] = 15>
		<CFSET shift[4][12] = 14>
		<CFSET shift[4][13] = 9>
		<CFSET shift[4][14] = 9>
		<CFSET shift[4][15] = 8>
		<CFSET shift[4][16] = 6>
		<CFSET shift[5][1] = 15>
		<CFSET shift[5][2] = 12>
		<CFSET shift[5][3] = 13>
		<CFSET shift[5][4] = 13>
		<CFSET shift[5][5] = 9>
		<CFSET shift[5][6] = 5>
		<CFSET shift[5][7] = 8>
		<CFSET shift[5][8] = 6>
		<CFSET shift[5][9] = 14>
		<CFSET shift[5][10] = 11>
		<CFSET shift[5][11] = 12>
		<CFSET shift[5][12] = 11>
		<CFSET shift[5][13] = 8>
		<CFSET shift[5][14] = 6>
		<CFSET shift[5][15] = 5>
		<CFSET shift[5][16] = 5>
		
		<CFSET k1 = ArrayNew(1)>
		<CFSET k2 = ArrayNew(1)>
		<CFSET r1 = ArrayNew(1)>
		<CFSET r2 = ArrayNew(1)>
		<CFSET s1 = ArrayNew(1)>
		<CFSET s2 = ArrayNew(1)>
		
		<CFLOOP index="i" from="1" to="16">
			
			<!--- define constants --->
			<CFSET k1[i] = 0>
			<CFSET k1[i+16] = Int(2^30*Sqr(2))>
			<CFSET k1[i+32] = Int(2^30*Sqr(3))>
			<CFSET k1[i+48] = Int(2^30*Sqr(5))>
			<CFSET k1[i+64] = Int(2^30*Sqr(7))>
			
			<CFSET k2[i] = Int(2^30*2^(1/3))>
			<CFSET k2[i+16] = Int(2^30*3^(1/3))>
			<CFSET k2[i+32] = Int(2^30*5^(1/3))>
			<CFSET k2[i+48] = Int(2^30*7^(1/3))>
			<CFSET k2[i+64] = 0>
			
			<!--- define word order --->
			<CFSET r1[i] = i-1>
			<CFSET r1[i+16] = rho[i]>
			<CFSET r1[i+32] = rho[rho[i]+1]>
			<CFSET r1[i+48] = rho[rho[rho[i]+1]+1]>
			<CFSET r1[i+64] = rho[rho[rho[rho[i]+1]+1]+1]>
			
			<CFSET r2[i] = pi[i]>
			<CFSET r2[i+16] = rho[pi[i]+1]>
			<CFSET r2[i+32] = rho[rho[pi[i]+1]+1]>
			<CFSET r2[i+48] = rho[rho[rho[pi[i]+1]+1]+1]>
			<CFSET r2[i+64] = rho[rho[rho[rho[pi[i]+1]+1]+1]+1]>
			
			<!--- define rotations --->
			<CFSET s1[i] = shift[1][r1[i]+1]>
			<CFSET s1[i+16] = shift[2][r1[i+16]+1]>
			<CFSET s1[i+32] = shift[3][r1[i+32]+1]>
			<CFSET s1[i+48] = shift[4][r1[i+48]+1]>
			<CFSET s1[i+64] = shift[5][r1[i+64]+1]>
			
			<CFSET s2[i] = shift[1][r2[i]+1]>
			<CFSET s2[i+16] = shift[2][r2[i+16]+1]>
			<CFSET s2[i+32] = shift[3][r2[i+32]+1]>
			<CFSET s2[i+48] = shift[4][r2[i+48]+1]>
			<CFSET s2[i+64] = shift[5][r2[i+64]+1]>
			
		</CFLOOP>
		
		<!--- define buffers --->
		<CFSET h = ArrayNew(1)>
		<CFSET h[1] = InputBaseN("0x67452301",16)>
		<CFSET h[2] = InputBaseN("0xefcdab89",16)>
		<CFSET h[3] = InputBaseN("0x98badcfe",16)>
		<CFSET h[4] = InputBaseN("0x10325476",16)>
		<CFSET h[5] = InputBaseN("0xc3d2e1f0",16)>
		
		<CFSET var1 = ArrayNew(1)>
		<CFSET var1[1] = "a1">
		<CFSET var1[2] = "b1">
		<CFSET var1[3] = "c1">
		<CFSET var1[4] = "d1">
		<CFSET var1[5] = "e1">
		
		<CFSET var2 = ArrayNew(1)>
		<CFSET var2[1] = "a2">
		<CFSET var2[2] = "b2">
		<CFSET var2[3] = "c2">
		<CFSET var2[4] = "d2">
		<CFSET var2[5] = "e2">
		
		<CFSET x = ArrayNew(1)>
		
		<!--- process msg in 16-word blocks --->
		<CFLOOP index="n" from="1" to="#Evaluate(Len(padded_hex_msg)/128)#">
			
			<CFSET a1 = h[1]>
			<CFSET b1 = h[2]>
			<CFSET c1 = h[3]>
			<CFSET d1 = h[4]>
			<CFSET e1 = h[5]>
			
			<CFSET a2 = h[1]>
			<CFSET b2 = h[2]>
			<CFSET c2 = h[3]>
			<CFSET d2 = h[4]>
			<CFSET e2 = h[5]>
			
			<CFSET msg_block = Mid(padded_hex_msg,128*(n-1)+1,128)>
			<CFLOOP index="i" from="1" to="16">
				<CFSET sub_block = "">
				<CFLOOP index="j" from="1" to="4">
					<CFSET sub_block = sub_block & Mid(msg_block,8*i-2*j+1,2)>
				</CFLOOP>
				<CFSET x[i] = InputBaseN(sub_block,16)>
			</CFLOOP>
			
			<CFLOOP index="j" from="1" to="80">
				
				<!--- nonlinear functions --->
				<CFIF j LE 16>
					<CFSET f1 = BitXor(BitXor(Evaluate(var1[2]),Evaluate(var1[3])),Evaluate(var1[4]))>
					<CFSET f2 = BitXor(Evaluate(var2[2]),BitOr(Evaluate(var2[3]),BitNot(Evaluate(var2[4]))))>
				<CFELSEIF j LE 32>
					<CFSET f1 = BitOr(BitAnd(Evaluate(var1[2]),Evaluate(var1[3])),BitAnd(BitNot(Evaluate(var1[2])),Evaluate(var1[4])))>
					<CFSET f2 = BitOr(BitAnd(Evaluate(var2[2]),Evaluate(var2[4])),BitAnd(Evaluate(var2[3]),BitNot(Evaluate(var2[4]))))>
				<CFELSEIF j LE 48>
					<CFSET f1 = BitXor(BitOr(Evaluate(var1[2]),BitNot(Evaluate(var1[3]))),Evaluate(var1[4]))>
					<CFSET f2 = BitXor(BitOr(Evaluate(var2[2]),BitNot(Evaluate(var2[3]))),Evaluate(var2[4]))>
				<CFELSEIF j LE 64>
					<CFSET f1 = BitOr(BitAnd(Evaluate(var1[2]),Evaluate(var1[4])),BitAnd(Evaluate(var1[3]),BitNot(Evaluate(var1[4]))))>
					<CFSET f2 = BitOr(BitAnd(Evaluate(var2[2]),Evaluate(var2[3])),BitAnd(BitNot(Evaluate(var2[2])),Evaluate(var2[4])))>
				<CFELSE>
					<CFSET f1 = BitXor(Evaluate(var1[2]),BitOr(Evaluate(var1[3]),BitNot(Evaluate(var1[4]))))>
					<CFSET f2 = BitXor(BitXor(Evaluate(var2[2]),Evaluate(var2[3])),Evaluate(var2[4]))>
				</CFIF>
				
				<CFSET temp = Evaluate(var1[1]) + f1 + x[r1[j]+1] + k1[j]>
				<CFLOOP condition="(temp LT -2^31) OR (temp GE 2^31)">
					<CFSET temp = temp - Sgn(temp)*2^32>
				</CFLOOP>
				<CFSET temp = BitOr(BitSHLN(temp,s1[j]),BitSHRN(temp,32-s1[j])) + Evaluate(var1[5])>
				<CFLOOP condition="(temp LT -2^31) OR (temp GE 2^31)">
					<CFSET temp = temp - Sgn(temp)*2^32>
				</CFLOOP>
				<CFSET temp = SetVariable(var1[1],temp)>
				<CFSET temp = SetVariable(var1[3],BitOr(BitSHLN(Evaluate(var1[3]),10),BitSHRN(Evaluate(var1[3]),32-10)))>
				
				<CFSET temp = var1[5]>
				<CFSET var1[5] = var1[4]>
				<CFSET var1[4] = var1[3]>
				<CFSET var1[3] = var1[2]>
				<CFSET var1[2] = var1[1]>
				<CFSET var1[1] = temp>
				
				<CFSET temp = Evaluate(var2[1]) + f2 + x[r2[j]+1] + k2[j]>
				<CFLOOP condition="(temp LT -2^31) OR (temp GE 2^31)">
					<CFSET temp = temp - Sgn(temp)*2^32>
				</CFLOOP>
				<CFSET temp = BitOr(BitSHLN(temp,s2[j]),BitSHRN(temp,32-s2[j])) + Evaluate(var2[5])>
				<CFLOOP condition="(temp LT -2^31) OR (temp GE 2^31)">
					<CFSET temp = temp - Sgn(temp)*2^32>
				</CFLOOP>
				<CFSET temp = SetVariable(var2[1],temp)>
				<CFSET temp = SetVariable(var2[3],BitOr(BitSHLN(Evaluate(var2[3]),10),BitSHRN(Evaluate(var2[3]),32-10)))>
				
				<CFSET temp = var2[5]>
				<CFSET var2[5] = var2[4]>
				<CFSET var2[4] = var2[3]>
				<CFSET var2[3] = var2[2]>
				<CFSET var2[2] = var2[1]>
				<CFSET var2[1] = temp>
				
			</CFLOOP>
			
			<CFSET t = h[2] + c1 + d2>
			<CFSET h[2] = h[3] + d1 + e2>
			<CFSET h[3] = h[4] + e1 + a2>
			<CFSET h[4] = h[5] + a1 + b2>
			<CFSET h[5] = h[1] + b1 + c2>
			<CFSET h[1] = t>
			
			<CFLOOP index="i" from="1" to="5">
				<CFLOOP condition="(h[i] LT -2^31) OR (h[i] GE 2^31)">
					<CFSET h[i] = h[i] - Sgn(h[i])*2^32>
				</CFLOOP>
			</CFLOOP>
			
		</CFLOOP>
		
		<CFLOOP index="i" from="1" to="5">
			<CFSET h[i] = Right(RepeatString("0",7)&UCase(FormatBaseN(h[i],16)),8)>
		</CFLOOP>
		
		<CFLOOP index="i" from="1" to="5">
			<CFSET temp = "">
			<CFLOOP index="j" from="1" to="4">
				<CFSET temp = temp & Mid(h[i],-2*(j-4)+1,2)>
			</CFLOOP>
			<CFSET h[i] = temp>
		</CFLOOP>
		
		<!--- <CFSET caller.msg_digest = h[1] & h[2] & h[3] & h[4] & h[5]> --->
		<cfreturn h[1] & h[2] & h[3] & h[4] & h[5]/>
	</cffunction>
	
</cfcomponent>