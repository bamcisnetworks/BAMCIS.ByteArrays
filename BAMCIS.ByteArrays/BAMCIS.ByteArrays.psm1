Function Set-ByteArrayPadding {
    <#
        .SYNOPSIS
            Pads an array with a leading byte so that the resulting array is the length specified.

        .DESCRIPTION
            This cmdlet takes an input array, creates a new array initialized with the padding byte specified, and
            then copies the supplied input array to the end of the new array. So if the array @(0x01, 0x02) was supplied with a padding
            byte of 0x03 and a length of 4, the resulting array would be @(0x03, 0x03, 0x01, 0x02).

            The original input array is unchanged and the resulting data is a new object returned to the pipeline if used with InputObject or supplied
            via the pipeline. The original array can be modified by use of the ReferenceObject parameter.

        .PARAMETER InputObject
            The array that needs to be padded.

        .PARAMETER ReferenceObject
            A reference to the array that needs to be padded. If this parameter is supplied, no output is returned to the pipeline

        .PARAMETER Length
            The desired length of the resulting array.

        .PARAMETER Padding
            The byte value used to pad the left hand side of the array. This defaults to 0x00.

        .PARAMETER PadEnd
            Instead of padding the left side of the array, the right side of the array is padded, so for an input of @(0x01) and a lenght of 4,
            the resulting array would be @(0x01, 0x00, 0x00, 0x00).

        .EXAMPLE
            $Arr = @(0x01)
            $Arr = $Arr | Set-ByteArrayPadding -Length 4

            The resulting array in $Arr is length 4 and its contents are: @(0x00, 0x00, 0x00, 0x01)

        .EXAMPLE
            $Arr = @(0x01)
            Set-ByteArrayPadding ([ref]$Arr) -Length 2 -Padding 0xFF -PadEnd

            The variable $Arr is modified by reference so that the original variable's contents after the cmdlet are @(0x01, 0xFF). Here the array
            is padded on the end with the specified 0xFF byte.

        .INPUTS
            System.Byte[]

        .OUTPUTS
            None or System.Byte[]

        .NOTES
            AUTHOR: Michael Haken
			LAST UPDATE: 1/19/2018
    #>
    [CmdletBinding()]
	[OutputType([System.Byte[]])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ParameterSetName = "Input")]
        [ValidateNotNull()]
        [System.Byte[]]$InputObject = @(),

        [Parameter(Position = 0, ParameterSetName = "Ref", Mandatory = $true)]
        [Ref]$ReferenceObject,

        [Parameter(Mandatory = $true, Position = 1)]
        [System.Int32]$Length,

        [Parameter(Position = 3)]
        [ValidateNotNull()]
        [System.Byte]$Padding = 0x00,

        [Parameter()]
        [Switch]$PadEnd
    )

    Begin {

    }

    Process {
        
        switch ($PSCmdlet.ParameterSetName)
        {
            "Input" {
                if ($InputObject.Length -lt $Length)
                {
                    [System.Byte[]]$NewData = [System.Byte[]](,$Padding * $Length)

                    [System.Int32]$CopyStartIndex = $Length - $InputObject.Length

                    if ($PadEnd)
                    {
                        $CopyStartIndex = 0
                    }

                    # Copy the original data to the new data array starting at the padding count index
		            # which will pad the new array with leading padding bytes
			
                    [System.Array]::Copy($InputObject, 0, $NewData, $CopyStartIndex, $InputObject.Length)

			        $InputObject = $NewData
                }

                Write-Output -InputObject $InputObject

                break
            }
            "Ref" {
                if ($ReferenceObject.Value.Length -lt $Length)
                {
                    [System.Byte[]]$NewData = [System.Byte[]](,$Padding * $Length)

                    [System.Int32]$CopyStartIndex = $Length - $ReferenceObject.Value.Length

                    if ($PadEnd)
                    {
                        $CopyStartIndex = 0
                    }

                    [System.Array]::Copy($ReferenceObject.Value, 0, $NewData, $CopyStartIndex, $ReferenceObject.Value.Length)

			        $ReferenceObject.Value = $NewData
                }

                break
            }
            default {
                Write-Error -Exception (New-Object -TypeName System.ArgumentException("Unknown parameter set, $($PSCmdlet.ParameterSetName), for $($MyInvocation.MyCommand).")) -ErrorAction Stop
            }
        }      
    }

    End {
    }
}

Function Remove-ByteArrayPadding {
    <#
        .SYNOPSIS 
            Removes padding from the beginning or end of a byte array.

        .DESCRIPTION
            This cmdlet removes the padding from the beginning or end of an array and provides a new or modified array
            with those bytes removed. The caller can specify the byte that is used as padding and provide the input array
            either through the pipeline, parameter, or by reference. When passed by reference, nothing is returned to
            the pipeline.

        .PARAMETER InputObject
            The byte array to remove padding from.

        .PARAMETER ReferenceObject
            The reference to a byte array that will have padding removed from it. The reference will point to a different 
            location in memory after the cmdlet is complete if any modifications have been done.

        .PARAMETER FromEnd
            Specifies that padding is removed from the tail end of the array instead of the beginning.

        .PARAMETER Padding
            The byte character that is used as padding to be removed. This defaults to 0x00.

        .EXAMPLE 
            $Arr = @(0x00, 0x00, 0x00, 0x01)
            Remove-ByteArrayPadding -InputObject $Arr

            The results of this cmdlet will produce a new array with contents @(0x01).

        .EXAMPLE
            $Arr = @(0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF)
            ([ref]$Arr) | Remove-ByteArrayPadding -Padding 0xFF -FromEnd

            This example demonstrates several things. First the input array can be passed by reference through the pipeline. 
            After the cmdlet complete, the variable $Arr will contain @(0x00, 0x00, 0x00, 0x01). The cmdlet specified the padding
            character to 0xFF and it removed the padding from the end of the array instead of the beginning.

        .INPUTS
            System.Byte[]

        .OUTPUTS
            System.Byte[] or None




    #>
    [CmdletBinding()]
    [OutputType([System.Byte[]])]
    Param(
        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = "Input")]
        [ValidateNotNull()]
        [System.Byte[]]$InputObject,

        [Parameter(ValueFromPipeline = $true, Position = 0, ParameterSetName = "Ref")]
        [ValidateNotNull()]
        [Ref]$ReferenceObject,

        [Parameter()]
        [Switch]$FromEnd,

        [Parameter()]
        [ValidateNotNull()]
        [System.Byte]$Padding = 0x00
    )

    Begin {
        [System.Byte[]]$Bytes = @()
    }

    Process {
        switch ($PSCmdlet.ParameterSetName)
        {
            "Input" {
                $Bytes += $InputObject
                break
            }
            "Ref" {
                $Bytes = $ReferenceObject.Value
                break
            }
            default {
                Write-Error -Exception (New-Object -TypeName System.ArgumentException("Unknown parameter set, $($PSCmdlet.ParameterSetName), for $($MyInvocation.MyCommand).")) -ErrorAction Stop
            }
        }
        
    }

    End {

        if ($FromEnd)
        {      
            $StartIndex = $Bytes.Length - 1

            while ($StartIndex -ge 0 -and $Bytes[$StartIndex] -eq $Padding)
            {
                $StartIndex--
            }

            if ($StartIndex -ge 0)
            {
                # Since StartIndex is the index where the first non zero byte is, add 1 to make it a length
                [System.Byte[]]$FinalBytes = New-Object -TypeName System.Byte[] -ArgumentList ($StartIndex + 1)

                [System.Array]::Copy($Bytes, 0, $FinalBytes, 0, $StartIndex + 1)

                $Bytes = $FinalBytes
            }
        }
        else
        {
            $StartIndex = 0

            while ($StartIndex -lt $Bytes.Length -and $Bytes[$StartIndex] -eq $Padding)
            {
                $StartIndex++
            }

            if ($StartIndex -lt $Bytes.Length)
            {
                [System.Byte[]]$FinalBytes = New-Object -TypeName System.Byte[] -ArgumentList ($Bytes.Length - $StartIndex)

                [System.Array]::Copy($Bytes, $StartIndex, $FinalBytes, 0, $Bytes.Length - $StartIndex)

                $Bytes = $FinalBytes
            }
        }

        switch ($PSCmdlet.ParameterSetName)
        {
            "Input" {
                Write-Output -InputObject $Bytes
                break
            }
            "Ref" {
                $ReferenceObject.Value = $Bytes
                break
            }
        }
    }
}

Function Out-Hex {
	<#
        .SYNOPSIS
            Outputs a byte array to stdout in a hex representation.

        .DESCRIPTION
            This cmdlet takes a byte array and writes it to the console in line lengths that are easier to read. If the input array is sent through 
            the pipeline, it does not need to be "protected" with a ',' to stop it from being unrolled.

        .PARAMETER InputObject
            The byte array to write to the console in hex.

        .PARAMETER Length
            The maximum number of bytes written to each line. This defaults to 8.

        .PARAMETER Delimiter
            The character used to separate each byte representation. This defaults to ' '.

        .EXAMPLE
            $Arr = @(0x01, 0x02, 0x03, 0x04)
            $Arr | Out-Hex -Length 2

            This writes out:
            01 02
            03 04

            In this case, the array $Arr is unrolled as it is sent to Out-Hex, so it ends up processing 4 separate Length 1 byte arrays.

        .EXAMPLE
            $Arr = @(0x01, 0x02, 0x03, 0x04, 0x05)
            $Arr | Out-Hex -Length 3

            This writes out:
            01 02 03
            04 05

            In this case, the array $Arr is not unrolled as it is sent to Out-Hex, so it ends up processing 1 array of length 5.

        .INPUTS
            System.Byte[]

        .OUTPUTS
            None

        .NOTES
            AUTHOR: Michael Haken
			LAST UPDATE: 1/19/2018
	#>
	[CmdletBinding()]
	[OutputType()]
    Param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNull()]
        [System.Byte[]]$InputObject,

        [Parameter()]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]$Length = 8,

        [Parameter()]
        [ValidateNotNull()]
        [System.Char]$Delimiter = ' '
    )

    Begin {
        # This method will handle an array passed via pipeline whether it is unrolled or not
        # Keep track on how many items we've added to a single line so we know when to add a 
        # new line
        [System.Int32]$LineCounter = 0
        [System.Text.StringBuilder]$SB = New-Object -TypeName System.Text.StringBuilder
    }

    Process {

        for ($i = 0; $i -lt $InputObject.Length; $i++)
        {
            $SB.Append($InputObject[$i + $j].ToString("X2") + $Delimiter) | Out-Null
            $LineCounter++

            # This pipeline input has finished the line, reset the line counter
            # and add the new line
            if ($LineCounter -eq $Length)
            {
                $LineCounter = 0

                # Trim the extra delimiter
                $SB.Length = $SB.Length - 1

                # Add the new line
                $SB.Append("`r`n") | Out-Null
            }            
        }
    }

    End {
        # Trim off the extra delimiters or new lines if they were added
        Write-Host ($SB.ToString().Trim())
    }
}

Function ConvertTo-OIDString {
    <#
		.SYNOPSIS
			Converts a byte array into an OID string.

		.DESCRIPTION
			This cmdlet accepts a byte array which is converted into an OID string.

		.PARAMETER InputObject
			The byte array to convert.

		.EXAMPLE
			$Arr = @(0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01)
			$OID = ConvertTo-OIDString $Arr

			This produces 1.2.840.113549.1.1.1 as the OID string, which is the OID for RSA Encryption

		.INPUTS
			System.Byte[]

		.OUTPUTS
			System.String

		.NOTES
            AUTHOR: Michael Haken
			LAST UPDATE: 1/20/2018
	#>	
	[CmdletBinding()]
	[OutputType([System.String])]
	Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateLength(3, [System.Int64]::MaxValue)]
        [System.Byte[]]$InputObject
    )

    Begin {
		# Make a new array to hold all of the input in case the array is unrolled by the pipeline
        [System.Byte[]]$Bytes = @()
    }

    Process {
		# Add each input to the collector in case the byte array is unrolled on the pipeline
        $Bytes += $InputObject
    }

    End {
		# Now that we have all the bytes to make the OID string, start processing them
        $Data = ""

        for ($i = 0; $i -lt $Bytes.Length; $i++)
        {
            if ($i -eq 0)
            {
                # Oid A.B.6.1....
				# Where A = 1 and B = 3
                # The first byte is computed by (A x 40) + B, first node times 40 plus the second node
                # To work backwords, do a modulo 40 to find the remainder, then subtract that from the value
                # to get a number divisible by 40 evenly to get the first node
                
                $Val = [System.Convert]::ToUInt32($Bytes[$i])
                [System.Int32]$SecondNode = $Val % 40
                [System.Int32]$FirstNode = ($Val - $SecondNode) / 40
                $Data += "$FirstNode.$SecondNode"
            }
            else
            {
				# All of the rest of the nodes are either less than or equal to 127, in which case they
				# contain the value directly, or they are 128 and greater and the value is stored in
				# multiple bytes
                if (($Bytes[$i] -band (1 -shl 7)) -ne 0)
                {
                    # Build new array to hold the bytes
                    [System.Byte[]]$Arr = @($Bytes[$i])

                    $OIDCounter = 1

                    while (($Bytes[$i + $OIDCounter] -band (1 -shl 7)) -ne 0)
                    {
                        # We don't care about the left most bit, it's just a marker
                        # that it is part of this node
                        $Arr += ($Bytes[$i + $OIDCounter] -band 0x7F)
                        $OIDCounter++
                    }

                    # This byte did not have a leading 1 and is the last byte
                    # to make up the variable length
                    $Arr += ($Bytes[$i + $OIDCounter] -band 0x7F)

                    # Skip however many bytes beyond the first we added to the array
                    $i += $Arr.Length - 1

                    # Take 7 bits from each byte and concatenate them

                    # This is the easiest way to make sure we grab 7 bits from each byte and concatenate
                    # them and is just as fast as bit shifting the individual bytes
                                       
                    [System.Text.StringBuilder]$SB = New-Object -TypeName System.Text.StringBuilder

                    for ($j = 0; $j -lt $Arr.Length; $j++)
                    {
						# Convert the byte to base 2, then pad the left with 0's to make sure
						# each string is 8 digits long
                        $Str = [System.Convert]::ToString($Arr[$j], 2).PadLeft(8, '0')

						# Drop off the most significant bit and append to the string builder
                        $SB.Append($Str.Substring(1)) | Out-Null
                    }

					# Convert our concatenated binary string to a UInt64 and tell the converter
					# we're coming from base 2
                    [System.UInt64]$Value = [System.Convert]::ToUInt64($SB.ToString(), 2)
                                        
                    # This approach also works, but is more prone to problems in case the Multiplier
                    # exceeds 8 bytes
                    <#
                    $Multiplier = 1

                    for ($j = $Arr.Length - 1; $j -gt 0; $j--)
                    {
                        # Move the bits from the left byte to right byte,
                        # as we move farther down, we need to move more bytes
                        $Arr[$j] = ($Arr[$j - 1] -shl (8 - $Multiplier)) -bor $Arr[$j]

                        # Shift down the left byte
                        $Arr[$j - 1] = $Arr[$j - 1] -shr (1 * $Multiplier++) 
                    }

                    $Arr = Set-ByteArrayPadding -InputObject $Arr -Length 8

                    if ([System.BitConverter]::IsLittleEndian)
                    {
                        [System.Array]::Reverse($Arr)
                    }

                    [System.UInt64]$Value = [System.BitConverter]::ToUInt64($Arr, 0)
                    #>

                    $Data += ".$Value"
                }
                else
                {
                    $Data += ".$([System.Convert]::ToUInt32($Bytes[$i]))"
                }
            }
        }

        Write-Output -InputObject $Data
    }
}

Function ConvertFrom-OIDString {
	<#
		.SYNOPSIS
			Creates a byte array from an OID string.

		.DESCRIPTION
			This cmdlet take an OID string in an X.Y.Z.W format and produces a byte array that is used 
			to represent the OID.

		.PARAMETER OID
			The OID string to convert to bytes.

		.EXAMPLE
			$Bytes = ConvertFrom-OIDString -OID "1.2.840.113549.1.1.1"

			The contents of $Bytes is (in decimal): 42 134 72 134 247 13 1 1 1

			In hex the contents are: 2A 86 48 86 F7 0D 01 01 01

			This is the RSA Encryption OID.

		.INPUTS
			System.String

		.OUTPUTS
			System.Byte[]

		.NOTES
            AUTHOR: Michael Haken
			LAST UPDATE: 1/22/2018
	#>
	[CmdletBinding()]
	[OutputType([System.String])]
	Param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$OID
	)

	Begin {

	}

	Process {
        # In case the OID components are seperated by spaces, replace those with 
        # periods, then split the parts on the periods
		[System.String[]]$Parts = $OID.Trim().Replace(' ', '.').Split('.')

        if ($Parts.Length -gt 2)
        {
            # This will hold all of the resulting bytes
		    [System.Byte[]]$Results = @()

            # Iterate each component of the OID string
		    for ($i = 0; $i -lt $Parts.Length; $i++)
		    {
                # The first two components require special handling, they
                # are composed from data in a single byte
			    if ($i -eq 0)
			    {
				    [System.UInt32]$High = $Parts[$i]
				    [System.UInt32]$Low = $Parts[$i + 1]

				    [System.UInt32]$FirstByte = ($High * 40) + $Low

				    [System.Byte[]]$Bytes = [System.BitConverter]::GetBytes($FirstByte)

                    if ([System.BitConverter]::IsLittleEndian)
                    {
                        [System.Array]::Reverse($Bytes)
                    }

                    # The GetBytes function will add 0x00 bytes to the result so that it is
                    # 4 bytes in length, but our result will only be 1 byte as part of the OID byte 
                    # array
                    $Bytes = Remove-ByteArrayPadding -InputObject $Bytes

                    $Results += $Bytes

                    # Skip the second the part since we already used it
                    $i += 1
			    }
                else
                {
                    # Get the byte integer value
                    [System.UInt32]$Value = $Parts[$i]

                    # If the value is less than 128, its value is just the byte
                    if ($Value -lt 128)
                    {
                        [System.Byte[]]$Bytes = [System.BitConverter]::GetBytes($Value)

                        if ([System.BitConverter]::IsLittleEndian)
                        {
                            [System.Array]::Reverse($Bytes)
                        }

                        # The GetBytes function will add 0x00 bytes to the result so that it is
                        # 4 bytes in length, but our result will only be 1 byte as part of the OID byte 
                        # array
                        $Bytes = Remove-ByteArrayPadding -InputObject $Bytes

                        $Results += $Bytes
                    }
                    else
                    {
                        # The value is greater than 128, which means it uses multiple bytes to
                        # store the value.

                        [System.String]$BitString = [System.Convert]::ToString($Value, 2)
     
                        # Count how many individual bit characters we've added to a string
                        $Counter = 0

                        # Store all the bytes making up this value here
                        [System.Byte[]]$Bytes = @()

                        # Used as a buffer to store 7 digit bit strings
                        $Line = ""

                        # Create the bytes from the bit string, starting at the end of the string
                        for ($j = $BitString.Length - 1; $j -ge 0; $j += -1)
                        {
                            $Line = "$($BitString[$j])$Line"

                            $Counter++

                            # Once index 6 is set (meaning we've filled 7 digits), the counter is incremented to 7
                            # and then we need to reset it to start a new byte, or if this is the last digit
                            # make sure the line is 8 digits long
                            if ($Counter -ge 7 -or $j -eq 0)
                            {
                                # Since the string is 7 digits or less long, add 0's to pad
                                # to 8 digits
                                $Line = $Line.PadLeft(8, '0')
                                [System.Byte]$Byte = [System.Convert]::ToByte($Line, 2)
                            
                                $Bytes += $Byte
                                $Counter = 0
                                $Line = ""
                            }
                        }

                        # The += adds the items to the end, but we started at the back of the
                        # bit string, so we need to reverse the items
                        [System.Array]::Reverse($Bytes)

                        # Make all of the bytes except the last have a 1 in the most significant bit
                        for ($j = 0; $j -lt $Bytes.Length - 1; $j++)
                        {
                            $Bytes[$j] = $Bytes[$j] -bor 0x80
                        }

                        $Results += $Bytes
                    }
                }
		    }

		    Write-Output -InputObject $Results
        }
        else
        {
            Write-Error -Exception (New-Object -TypeName System.ArgumentException("The OID string was not correctly formatted, it should include at least 2 parts separated by a period.")) -ErrorAction Stop
        }
	}

	End {
	}
}