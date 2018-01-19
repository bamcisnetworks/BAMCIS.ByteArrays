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