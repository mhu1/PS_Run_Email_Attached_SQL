cls
#Write-Host $a
#Start-Process Outlook
$ol = New-Object -comObject Outlook.Application
$mail = $ol.CreateItem(0)
$n = $ol.GetNamespace("MAPI")
#$f = $n.PickFolder()
$f = $n.GetDefaultFolder("olFolderInbox")
 
#$filepath = "X:\DWH_DBScripts\" +(Get-Date).Year+"_0"+(Get-Date).Month+"_"+(Get-date).Day
$begin = Get-Date -Format d
$filepath="X:\DWH_DBScripts\BGDBA"
$f.Items.Restrict("[ReceivedTime]>'" + $begin +"' and [Unread]=true")|foreach {
#write-host $_.subject,$_.SenderName;$_.To;$_.Name;$_.Body
                      
       if (($_.Body -like "*execute*" -and  $_.Body -like "*attached*" -and  $_.Body -like "*production*" -and  $_.Body -notlike "*at 5 pm*") -or $_.Body -like "*vm1psql01*")
 
        {
            $sqlServer="vm1psql01,23341";
            if ($_.Body -like "ASR")
            {
                $Database="ASRSIP"
            }
            if ($_.Body -like "*CapitalOne_ING*") 
            {
                $Database ="CapitalOne_ING"          
                
            }
            #ASRHIP_ Reporting
            if ($_.Body -like "*ASR*" -and $_.Body -like "*Reporting*")
            {
                $Database="ASRHIP_Reporting"
            }
            if ($_.Body -like "*CapitalOneBestBuy*" )
            {
                $Database="CapitalOneBestBuy"
            }
            #NuvaRing
            if ($_.Body -like "*NuvaRing*" )
            {
                $Database="NuvaRing"
            }
            #Nuvaring_Reporting
            if ($_.Body -like "*NuvaRing*" -and $_.Body -like "*Reporting*")
            {
                $Database="Nuvaring_Reporting"
            }
            
        }
        if (($_.subject -like "*Staging*" -and $_.Body -like "*execute*" -and  $_.Body -like "*attached*" -and  $_.Body -notlike "*from Train*" )  -or $_.Body -like "*VM1DEVSQL2*")
        {
            $sqlServer="VM1DEVSQL2";
            if ($_.Body -like "*ASRHip_Sandbox_Reporting*") 
            {
                $Database ="ASRHip_Sandbox_Reporting"          
                
            }
            if ($_.Body -like "*ASR_Staging*") 
            {
                $Database ="ASRHip_Staging"          
                
            }
           
             if ($_.Body -like "*ASRHIP_Staging_Reporting*") 
            {
                $Database ="ASRHIP_Staging_Reporting"          
                
            }
            #CapitalOne_ING - Push to Staging,CapitalOneING - Push to Staging
            if ($_.subject -like "*CapitalOne*" -and $_.subject -like "*ING*") 
            {
                $Database ="CapitalOne_ING"          
                
            }
            #CapOne TCPA : Payment Utility
           
            if ($_.subject -like "*CapitalOne*" -and $_.subject -like "*ING*") 
            {
                $Database ="CapitalOne_ING"          
                
            }
            #CapitalOneTCPA_Reporting_Staging
            if ($_.subject -like "*CapitalOneTCPA*" -and $_.subject -like "*Reporting*") 
            {
                $Database ="CapitalOneTCPA_Reporting_Staging"          
                
            }
            #NuvaRing
            if ($_.Body -like "*NuvaRing*" )
            {
                $Database="NuvaRing"
            }
           
            #NuvaRing
            if ($_.Body -like "*NuvaRing*" -and $_.Body -like "*Staging*")
            {
                $Database="NuvaRing_Staging"
            }
            #NuvaRing
            if ($_.Body -like "*NuvaRing*" -and $_.Body -like "*Sandbox*")
            {
                $Database="NuvaRing_Sandbox"
            }
          
        }
        #Please execute the attached scripts in ASRHip_Reporting.
        if ($_.Body -like "*execute*" -and  $_.Body -like "*attached*" -and  $_.Body -like "*ASRHip_Reporting*" )
 
        {
            $sqlServer="vm1psql01,23341";
            $Database="ASRHip_Reporting"
        }   
       
                
       
         
         write-host $sqlServer
         write-host $Database
                 
        
         if ($sqlServer -ne $null)
         {
          $_.attachments|foreach {
             #Write-Host $_.filename
             $a = $_.filename
             If ($a.Contains("sql"))
                 {
                    $_.saveasfile((Join-Path $filepath "$a"))             
                       $ps = [PowerShell]::Create()
                      [ref]$e = New-Object System.Management.Automation.Runspaces.PSSnapInException
                      $ps.Runspace.RunspaceConfiguration.AddPSSnapIn( "SqlServerCmdletSnapin100", $e ) | Out-Null
                     
                      $MyQuery="Use "+$Database+"`r`n"
                      $MyQuery+="Go "+"`r`n"
                      $MyQuery += get-content $filepath\$a | Out-String;
                     write-host  $MyQuery
                      $ps.AddCommand( "Invoke-Sqlcmd" ).AddParameter( "Query", $MyQuery ).AddParameter( "Verbose" ).AddParameter( "serverinstance",$sqlServer)
                      $ps.Invoke()
                      $ps.Streams
                      #$a=$a -Replace ".sql","_Log.txt"
                      $a=$a -Replace ".sql","$(Get-Date -Format "MMddyyyy-HHmmss")_Log.txt"
                      #$(Get-Date -Format "MMddyyyy-HHmmss
                      #Move-Item $a.FullName "$a.FullName -replace "_log ", "_Ran" -replace '\.([^\.]+)$')-$(Get-Date -Format "MMddyyyy-HHmmss")"
 
                      $ps.Streams.Verbose | % { $_.Message | Out-File -Append $filepath\$a }
                   
                 
                 }             
               }
                    #cls
                    $QueryResultMessage = get-content $filepath\$a | Out-String;                                       
                    $mailBody = @()
                    $mailBody += "Completed automatically for testing."
                    $mailBody += $QueryResultMessage
                    $Signature = "`n`nBest Regards,`nMark Hu `nDatabase Administrator `nBROWNGREER PLC `nCell: (972) 987-0186 `nwww.BrownGreer.com `nmhu@browngreer.com"
                    #$Signature = "`n`nBest Regards,`nChristian Bjornnes  `nDatabase Administrator `nBROWNGREER PLC `nwww.BrownGreer.com `cbjornnes@browngreer.com"
                   
                    $mailBody +=$Signature
                    $mailBody +="------------------------------------------"                  
                    $mailBody +=$_.Body 
                    $mailBody | Out-File -Append $filepath\"EmailBody$a.txt"
                                      
                    $mail = $ol.CreateItem(0)
                    $mail.subject = "RE:"+$_.subject
                    $mail.body = Get-Content $filepath\"EmailBody$a.txt" | Out-String;
                    $mail.To=$_.SenderName
                    $mail.cc=$_.cc
                    $mail.Send()
                   
                                       
         #relay.browngreer.com    
              
         }                          
        }
 