function Get-TimeFromTags {
    [CmdletBinding()]
    param (
        $Tags
    )

    begin {
        $FIXED_TAGS = [PSCustomObject] $script:CONFIG.TAGS
    }

    process {
        $Datetime = Get-Date
        $UTCTimeActual = $Datetime.ToUniversalTime()
        Write-Verbose "[$(Get-Date)] Actual Time (UTC) is $UTCTimeActual"

        $UTCOffset = [INT]$Tags[$FIXED_TAGS.POWER_OFF_OFFSET] * -1
        Write-Verbose "[$(Get-Date)] UTC Offset is $UTCOffset"

        # Determine Shut Down Time
        $LocalStopString = $Tags[$FIXED_TAGS.POWER_OFF]
        $LocalStopTime = Get-Date $LocalStopString
        $UTCStopTime = $LocalStopTime.AddHours($UTCOffset)

            # Remove 24h and 5 Minutes to avoid 00:00 / midnight when UTC Offset is set to -5h or more (USA)
        $ActualCheckDate = Get-Date
        if ($UTCOffset -ge 5 -and $ActualCheckDate -ge (Get-Date "00:00:01") -and $ActualCheckDate -le (Get-Date "10:00")) {
            $UTCStopTime = $UTCStopTime.AddMinutes(-1445)
        }
        Write-Verbose "[$(Get-Date)] Stop Time (UTC) is $UTCStopTime"

        # Determine Start Time
        $LocalStartString = $Tags[$FIXED_TAGS.POWER_ON]
        $LocalStartTime = Get-Date $LocalStartString
        $UTCStartTime = $LocalStartTime.AddHours($UTCOffset)
        Write-Verbose "[$(Get-Date)] Start Time (UTC) is $UTCStartTime"

        # Get Date for Date exclusions

        # TODO: Clean up this mess
        $UTCOffsetDate = [INT]$Tags['PowerOnOffUTCOffset'] # TODO: Rename variable to UtcOffset...
        [STRING]$ShutDownExclusion = $Tags['PowerOffExcludeDate']
        if (!$ShutDownExclusion) {
            [DateTime]$ShutDownExclusionFormated = "01/01/1990"
        }
        else {
            [DateTime]$ShutDownExclusionFormated = $ShutDownExclusion
        }

        # TODO: Rename those variables and create some sense here.
        $ActualOffsetDate = (Get-Date).AddHours($UTCOffsetDate)
        $ActualOffsetDateFormated = Get-Date -Date $ActualOffsetDate -Format "MM/dd/yyyy"
        $ShutDownDateExclusionFormated = Get-Date -Date $ShutDownExclusionFormated -Format "MM/dd/yyyy"
        $ShutDownDate = (Get-Date -Date $ShutDownExclusionFormated).AddHours(25)
        $ShutDownDateFormated = Get-Date -Date $ShutDownDate -Format "MM/dd/yyyy"

        return [PSCustomObject]@{
            UTCTimeActual = $UTCTimeActual
            UTCStartTime  = $UTCStartTime
            UTCStopTime   = $UTCStopTime
            UTCOffset     = $UTCOffset
            ShutDownDateFormated = $ShutDownDateFormated
            ShutDownDateExclusionFormated = $ShutDownDateExclusionFormated
            ActualOffsetDateFormated      = $ActualOffsetDateFormated
            ShutDownExclusionFormated     = $ShutDownExclusionFormated
        }
    }

    end {

    }
}