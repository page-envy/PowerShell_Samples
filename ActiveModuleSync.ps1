# ActiveModuleSync.ps1  #
# Author: Nick Page    #
# Version: 1.0         #
# Date: 10 January 2017 #
#-------------------------------------------------------------------------------
# This script is in charge of mounting App-V packages one-by-one, until everything
# has been mounted. Logs are created to track mounting duration of the packages.
# Mounting will only occur if the computer does not currently have a user logged
# in and it has been idle for 10 minutes. This is set as a Scheduled Task.
#-------------------------------------------------------------------------------

Import-Module AppVClient
if((Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Faronics\"Deep Freeze 6")."DF Status" -eq "Frozen"){
    Start-Sleep 10

    # Set up local script variables
    $packageList = Get-AppvClientPackage
    $connectionGroupList = Get-AppvClientConnectionGroup
    $Log_Date = get-date -Format MM-dd-yyyy
    $packageListCount = $packageList.Count
    $cgCount = $connectionGroupList.Count
    $installedCount = 0
    $cgMountCount = 0

    # Pull variables from environmental variables
    if([Environment]::GetEnvironmentVariable("APPV_COMPLETE","Machine") -eq "YES"){
        # Double check to see if applications are actually complete.
        $completeAppsList = Get-AppvClientPackage | Where PercentLoaded -eq 100
        $completeCGList = Get-AppvClientConnectionGroup | Where PercentLoaded -eq 100
        if($completeAppsList.Count -eq $packageListCount){
            if($completeCGList.Count -eq $cgCount){
                $finishedMounting = 2
            }
            else{
                $finishedMounting = 0
            }
        }
        else{
            $finishedMounting = 0
            "                                    " | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
            "                                    " | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
            "------------------------------------" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
            "~~Package Mount Error, Restarting..." | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
            "------------------------------------" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
            "                                    " | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
            "                                    " | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
        }
    }
    elseif([Environment]::GetEnvironmentVariable("APPV_COMPLETE","Machine") -eq "ALMOST"){
        $finishedMounting = 1
    }
    else{
        $finishedMounting = 0
    }

    if($finishedMounting -eq 2){
        $time = get-date -format HH:mm:ss
        "~~~ $time - All packages appear to be mounted." | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
        break
    }
    else{
        "-------------------------------" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
        "BEGIN App-V Mounting Process..." | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
        "-------------------------------" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii

        for($i=0; $i -le 10000; $i++){
            # A user is currently logged on
            if([Environment]::GetEnvironmentVariable("AT_IDLE","Machine") -eq "NO"){
                $time = get-date -format HH:mm:ss
                "xxx $time - User is currently logged in, trying again in 5 minutes...`r`n" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                sleep 300
            }
            else{# no user logged on
                ForEach( $package in $packageList ){
                    if( $package.PercentLoaded -ne 100 ){
                        if([Environment]::GetEnvironmentVariable("AT_IDLE","Machine") -eq "YES"){
                            $name = $package.Name
                            $startTime = get-date -format HH:mm:ss
                            "$startTime - BEGIN Mounting $name" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                            
                            Mount-AppvClientPackage -Package $package
                            
                            $endTime = get-date -format HH:mm:ss
                            $timeSpan = New-TimeSpan -Start $startTime -End $endTime
                            "+++ $endTime - Successfully Mounted $name! Total time: $timeSpan`r`n" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                        }
                        else{
                            $time = get-date -format HH:mm:ss
                            "xxx $time - User logon interrupted mount process" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                            break
                        }
                    }
                    else{
                        #$name = $package.Name
                        $installedCount++
                    }
                }
                "-----------------------------" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                "Mounting Connection Groups..." | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                "-----------------------------" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                ForEach( $cg in $connectionGroupList ){
                    if( $cg.percentLoaded -ne 100 ){
                        if([Environment]::GetEnvironmentVariable("AT_IDLE","Machine") -eq "YES"){
                            $cgName = $cg.Name
                            $startTime = get-date -format HH:mm:ss
                            "$startTime - BEGIN Mounting Connection Group $cgName" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                            
                            Mount-AppvClientConnectionGroup -Name $cgName
                            
                            $endTime = get-date -format HH:mm:ss
                            $timeSpan = New-TimeSpan -Start $startTime -End $endTime
                            "+++ $endTime - Successfully Mounted Connection Group $cgName! Total time: $timeSpan`r`n" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                        }
                        else{
                            $time = get-date -format HH:mm:ss
                            "xxx $time - User logon interrupted mount process" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                            break
                        }
                    }
                    else{
                        $cgMountCount++
                    }
                }
            }
            
            # Proceed to second pass if it appears that everything is mounted properly
            if($installedCount -ge $packageListCount){
                if( $cgMountCount -ge $cgCount ){
                    $finishedMounting = 1
                }
            }
            else{}
            # Second pass to double check 
            if($finishedMounting -eq 1){
                # Populate any unfinished packages
                $secondPassAppList = Get-AppvClientPackage | Where PercentLoaded -ne 100
                $secondPassCGList = Get-AppvClientConnectionGroup | Where PercentLoaded -ne 100
                $time = get-date -format HH:mm:ss
                "-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                "$time - Verification Pass starting..." | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                "-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                
                # Mount all unfinished packages
                foreach($app in $secondPassAppList){
                    if($app.Percentloaded -ne 100){
                        if([Environment]::GetEnvironmentVariable("AT_IDLE","Machine") -eq "YES"){
                            $name = $app.Name
                            $time = get-date -format HH:mm:ss
                            $startTime = get-date -format HH:mm:ss
                            "$startTime - BEGIN Mounting $name" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                            Mount-AppvClientPackage -Package $app
                            $endTime = get-date -format HH:mm:ss
                            $timeSpan = New-TimeSpan -Start $startTime -End $endTime
                            "+++ $endTime - Successfully Mounted $name! Total time: $timeSpan`r`n" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                        }
                        else{
                            $time = get-date -format HH:mm:ss
                            "xxx $time - User logon interrupted mount process" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                            break
                        }
                    }
                    else{
                        # Do Nothing
                    }
                }
                ForEach( $cg2 in $secondPassCGList ){
                    if($cg2.percentLoaded -ne 100){
                        if([Environment]::GetEnvironmentVariable("AT_IDLE","Machine") -eq "YES"){
                            $cgName = $cg2.Name
                            $startTime = get-date -format HH:mm:ss
                            "$startTime - BEGIN Mounting Connection Group $cgName" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                            
                            Mount-AppvClientConnectionGroup -Name $cgName
                            
                            $endTime = get-date -format HH:mm:ss
                            $timeSpan = New-TimeSpan -Start $startTime -End $endTime
                            "+++ $endTime - Successfully Mounted Connection Group $cgName! Total time: $timeSpan`r`n" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                        }
                        else{
                            $time = get-date -format HH:mm:ss
                            "xxx $time - User logon interrupted mount process" | Out-File "T:\AppV_Load_$Log_Date.log" -append -encoding ascii
                            break
                        }
                    }
                    else{
                        # Do Nothing
                    }
                }
                
                # Re-Query unfinished appvclientpackage list
                $secondPassAppList = Get-AppvClientPackage | Where PercentLoaded -ne 100
                $secondPassCGList = Get-AppvClientConnectionGroup | Where PercentLoaded -ne 100
                
                if(($secondPassAppList.Count -eq 0) -and ($secondPassCGList.Count -eq 0)){
                    # Everything is mounted if there are no more appvclientpackages under 100 percent loaded
                    $finishedMounting = 2
                    $i = 10001
                }
                else{}
            }
            if($finishedMounting -eq 2){
	    	# Apps are completely mounted
                [Environment]::SetEnvironmentVariable('APPV_COMPLETE', "YES" , 'Machine')
                break
            }
        }
    }
}
else{
    # Do nothing, computer is thawed
}
