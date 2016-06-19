#tag Class
Protected Class Hashids
	#tag Method, Flags = &h0
		Sub Constructor()
		  P_Init( "", 0, kAlphabet )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(saltStr As String, minHashLen As Integer, alphaStr As String)
		  P_Init( saltStr, minHashLen, alphaStr )
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Decode(hashStr As String, forceArray As Boolean = False) As Variant
		  If hashStr = "" Then
		    Return Nil
		  End If
		  
		  Return P_Decode(hashStr, self.Alphabet, forceArray)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DecodeHex(hashStr As String) As Variant
		  Dim nums As Variant, num As integer
		  Dim hexStr As String
		  Dim list() As Integer
		  
		  If hashStr = "" Then
		    Return Nil
		  End If
		  
		  nums = P_Decode(hashStr, Me.Alphabet, True)
		  
		  if nums.IsArray then
		    list = nums
		  else
		    list.Append nums.IntegerValue
		  end if
		  
		  hexStr = ""
		  For Each num In list
		    hexStr = hexStr + Mid(Hex(num),2)
		  Next num
		  
		  Return hexStr
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Decrypt(hashStr As String, forceArray As Boolean = False) As Variant
		  //Alias of Decode
		  
		  Return Decode(hashStr)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Encode(nums() as Integer) As String
		  
		  Dim i As Integer
		  Dim num As Integer, tmpNum As Integer
		  
		  
		  
		  i = 0
		  For Each num In nums
		    
		    If num < 0 Then
		      Dim err As new RuntimeException
		      err.Message = "Non positive/integer value in Encode list"
		      Raise Err
		    End If
		    i = i + 1
		  Next
		  
		  If i = 0 Then
		    // empty array
		    Return ""
		  Else
		    Return P_Encode(nums)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Encode(ParamArray vars() as Integer) As String
		  
		  Return Encode(vars)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EncodeHex(hexStr As String) As String
		  Dim i As Integer, nums() As Variant, tmp As String
		  
		  hexStr = CStr(hexStr)
		  
		  // Ensure only hex characters
		  For i = 1 To Len(hexStr) Step 1
		    If InStrB(1, kHex, Mid(hexStr, i, 1)) < 1 Then
		      Return ""
		    End If
		  Next
		  
		  // Break the input string into groups of 12 hex chars max
		  // and convert to decimal
		  i = 0
		  While Len(hexStr) > 0
		    ReDim nums(i)
		    nums(i) = Hex2Dec("1" + Left(hexStr, 12))
		    hexStr = Mid(hexStr, 13)
		    i = i + 1
		  Wend
		  
		  // Encode the numbers
		  If i = 0 Then
		    // empty strig
		    Return ""
		  Else
		    Return P_Encode(nums)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Encrypt(ParamArray nums() As Integer) As String
		  //Alias of Encode
		  
		  Return Encode(nums())
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Hex2Dec(hexStr As String) As Double
		  
		  
		  Return val("&h" + hexStr)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Params(saltStr As String = "", minHashLen As Integer = 0, alphabetStr as String = "")
		  if alphabetStr.Trim = "" then
		    alphabetStr = kAlphabet
		  end if
		  
		  //Compute the gards and seps
		  P_Init( saltStr, minHashLen, alphabetStr)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function P_ConsistentShuffle(alphaStr As String, saltStr As String = "") As String
		  Dim tmpa As String, tmpb As String
		  Dim n As Integer, i As Integer, j As Integer, v As Integer, p As Integer
		  
		  If Len(saltStr) = 0 Then
		    Return alphaStr
		  Else
		    i = Len(alphaStr) - 1
		    While i > 0
		      v = v Mod Len(saltStr)
		      n = Asc(Mid(saltStr, v + 1, 1))
		      p = p + n
		      j = (n + v + p) Mod i
		      tmpa = Mid(alphaStr, i + 1, 1)
		      tmpb = Mid(alphaStr, j + 1, 1)
		      alphaStr = Mid(alphaStr, 1, i) + tmpb + Mid(alphaStr, i + 2)
		      alphaStr = Mid(alphaStr, 1, j) + tmpa + Mid(alphaStr, j + 2)
		      i = i - 1
		      v = v + 1
		    Wend
		    Return alphaStr
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function P_Decode(hashStr As String, alphaStr As String, forceArray As Boolean = False) As Variant
		  Dim nums() As Variant, hashArray() As String
		  Dim i As Integer, l As Integer
		  Dim lottery As String, subHash As String, buffer As String
		  Dim c As String
		  
		  ' Strip out guards
		  For i = 1 To Len(Me.Guards)
		    c = Mid(Me.Guards, i, 1)
		    hashStr = ReplaceAllB(hashStr, c, " ")
		  Next
		  hashArray = SplitB(hashStr, " ")
		  i = 0
		  l = UBound(hashArray) + 1
		  If l = 3 Or l = 2 Then
		    i = 1
		  End If
		  hashStr = hashArray(i)
		  If hashStr = "" Then
		    Return Nil
		  End If
		  
		  lottery = Left(hashStr, 1)
		  hashStr = Mid(hashStr, 2)
		  
		  ' Break into array of number hashes
		  For i = 1 To Len(Me.Seps)
		    c = Mid(Me.Seps, i, 1)
		    hashStr = ReplaceAllB(hashStr, c, " ")
		  Next
		  hashArray = SplitB(hashStr, " ")
		  
		  ' Decode each number in the hash array
		  i = 0
		  For Each subHash In hashArray
		    ReDim nums(i)
		    buffer = Left(lottery + Me.Salt + alphaStr, Len(alphaStr))
		    alphaStr = P_ConsistentShuffle(alphaStr, buffer)
		    nums(i) = P_UnHash(subHash, alphaStr)
		    i = i + 1
		  Next
		  
		  If i = 1 And Not forceArray Then
		    Return nums(0)
		  Else
		    Return nums
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function P_Encode(vList As Variant) As String
		  Dim lottery As String, buffer As String, alpha As String
		  Dim ret As String, guard As String, lst As String
		  Dim num As Variant, nums() As Integer
		  Dim i As Integer, sepsIdx As Integer, guardIdx As Integer
		  Dim half As Integer, excess As Integer, numSize As Integer
		  Dim numHashInt As Integer
		  
		  if vList.IsArray then
		    nums = vList
		  else
		    nums.Append vList.IntegerValue
		  end if
		  
		  
		  alpha = Me.Alphabet
		  numSize = UBound(nums) + 1
		  numHashInt = 0
		  
		  i = 0
		  For Each num In nums
		    numHashInt = numHashInt + (num mod (i + 100))
		    i = i + 1
		  Next num
		  
		  lottery = Mid(alpha, (numHashInt Mod Len(alpha)) + 1, 1)
		  ret = lottery
		  
		  i = 0
		  For Each num In nums
		    buffer = lottery + Me.Salt + alpha
		    alpha = P_ConsistentShuffle(alpha, Mid(buffer, 1, Len(alpha)))
		    lst = P_Hash(num, alpha)
		    ret = ret + lst
		    If (i + 1) < numSize Then
		      num = (num mod (Asc(lst) + i))
		      sepsIdx = (num mod Len(Me.Seps))
		      ret = ret + Mid(Me.Seps, sepsIdx + 1, 1)
		    End If
		    i = i + 1
		  Next num
		  
		  If Len(ret) < Me.MinHashLength Then
		    guardIdx = (numHashInt + Asc(Mid(ret, 1, 1))) Mod Len(Me.Guards)
		    guard = Mid(Me.Guards, guardIdx + 1, 1)
		    ret = guard + ret
		    If Len(ret) < Me.MinHashLength Then
		      guardIdx = (numHashInt + Asc(Mid(ret, 3, 1))) Mod Len(Me.Guards)
		      guard = Mid(Me.Guards, guardIdx + 1, 1)
		      ret = ret + guard
		    End If
		  End If
		  
		  half = (Len(alpha) / 2)
		  While Len(ret) < Me.MinHashLength
		    alpha = P_ConsistentShuffle(alpha, alpha)
		    ret = Mid(alpha, half + 1) + ret + Mid(alpha, 1, half)
		    excess = Len(ret) - Me.MinHashLength
		    If excess > 0 Then
		      ret = Mid(ret, (excess \ 2) + 1, Me.MinHashLength)
		    End If
		  Wend
		  
		  Return ret
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function P_Hash(num As Integer, alphaStr As String) As String
		  Dim hash As String
		  Dim la As Integer, pos As Integer
		  
		  'num = CDec(num)
		  hash = ""
		  la = Len(alphaStr)
		  
		  Do
		    pos = num mod la
		    hash = Mid(alphaStr, pos + 1, 1) + hash
		    num = num / la
		  Loop Until num = 0
		  
		  Return hash
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub P_Init(saltStr As String, minHashLen As Integer, alphaStr As String)
		  Dim uniqueStr As String, c As String, g As Integer
		  Dim i As Integer, l As Integer, d As Integer
		  
		  Seps = kseps
		  Guards = ""
		  Salt = saltStr
		  MinHashLength = minHashLen
		  Alphabet = alphaStr
		  
		  // Ensure alphabet only has uniqueStr characters
		  uniqueStr = ""
		  For i = 1 To Len(Me.Alphabet)
		    If InStrB(uniqueStr, Mid(Alphabet, i, 1)) = 0 Then
		      uniqueStr = uniqueStr + Mid(Alphabet, i, 1)
		    End If
		  Next
		  Alphabet = uniqueStr
		  
		  If InStrB(Alphabet, " ") > 0 Then
		    // Alphabet cannot contain spaces
		    Dim err As new RuntimeException
		    err.Message = "Alphabet cannot contain spaces"
		    Raise err
		    
		  ElseIf Len(Alphabet) < 16 Then
		    // Alphabet must be at least 16 characters
		    Dim err As new RuntimeException
		    err.Message = "Alphabet must contain at least " + str(kminAlphaLen) + " unique characters"
		    Raise err
		  End If
		  
		  // Seps must be from alphabet and alphabet cannot contain seps
		  Seps = ""
		  For i = 1 To Len(kseps) Step 1
		    c = Mid(kseps, i, 1)
		    If InStrB(Alphabet, c) > 0 Then
		      Seps = Seps + c
		      Alphabet = ReplaceAllB(Alphabet, c, "")
		    End If
		  Next
		  Seps = P_ConsistentShuffle(Seps, Salt)
		  
		  If Len(Seps) = 0 Or (Len(Alphabet) / Len(Seps)) > ksepDiv Then
		    l = Ceil(Len(Alphabet) / ksepDiv)
		    If l = 1 Then
		      l = 2
		    End If
		    If l > Len(Me.Seps) Then
		      d = l - Len(Me.Seps)
		      Seps = Seps + Mid(Alphabet, 1, d)
		      Alphabet = Mid(Alphabet, d + 1)
		    Else
		      Seps = Mid(Seps, 1, l)
		    End If
		  End If
		  
		  Alphabet = P_ConsistentShuffle(Alphabet, Salt)
		  g = Ceil(Len(Alphabet) / kguardDiv)
		  If Len(Alphabet) < 3 Then
		    Guards = Mid(Seps, 1, g)
		    Seps = Mid(Seps, g + 1)
		  Else
		    Guards = Mid(Alphabet, 1, g)
		    Alphabet = Mid(Alphabet, g + 1)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function P_UnHash(hashStr As String, alphaStr As String) As Integer
		  Dim i As Integer, pos As Integer, lh As Integer, la As Integer
		  Dim num As Integer
		  
		  num = 0
		  lh = Len(hashStr)
		  la = Len(alphaStr)
		  
		  For i = 1 To lh Step 1
		    pos = (InStrB(alphaStr, Mid(hashStr, i, 1)) - 1)
		    num = num + ((pos) * (la ^ (lh - i)))
		  Next
		  
		  Return num
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private alphabet As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private guards As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private minHashLength As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private p_salt As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return p_Salt
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  p_salt = value
			End Set
		#tag EndSetter
		Salt As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private seps As String
	#tag EndProperty


	#tag Constant, Name = kAlphabet, Type = String, Dynamic = False, Default = \"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", Scope = Public
	#tag EndConstant

	#tag Constant, Name = kguardDiv, Type = Double, Dynamic = False, Default = \"12", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kHex, Type = String, Dynamic = False, Default = \"0123456789abcdefABCDEF", Scope = Public
	#tag EndConstant

	#tag Constant, Name = kminAlphaLen, Type = Double, Dynamic = False, Default = \"16", Scope = Private
	#tag EndConstant

	#tag Constant, Name = ksepDiv, Type = Double, Dynamic = False, Default = \"3.5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kseps, Type = String, Dynamic = False, Default = \"cfhistuCFHISTU", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kVersion, Type = String, Dynamic = False, Default = \"1.0.0", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Salt"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
