# Daily Trellix tools
# Author - Michael Ising
# Version 3.1 Oct 2024
# Before use, edit all entries found between {{ }} to match your environment and delete the {{ }}
# Example: Remove-ADGroupMember -identity '{{AD Group Name Here}}' -Members $computer"$" -Confirm:$false 
# would become Remove-ADGroupMember -identity 'Quarantine Group' -Members $computer"$" -Confirm:$false
function Show-Menu
{
    param (
        [string]$Title = 'Common Tools Menu'
    )
    Clear-Host
    Write-Host "=================$Title================" -ForegroundColor Cyan

    Write-Host "1:  Remote WakeUp" -ForegroundColor Cyan
    Write-Host "2:  Get Computer AD Groups" -ForegroundColor Cyan
    Write-Host "3:  Remove System from HBSS Security Groups" -ForegroundColor Cyan
    Write-Host "4:  Update AMCore" -ForegroundColor Cyan
    Write-Host "5:  Get McAfee Info" -ForegroundColor Cyan
    Write-Host "6:  Copy Endpoint Removal Tool to Computer" -ForegroundColor Cyan
    Write-Host "7:  Remove ENS from computer (Run 6 first)" -ForegroundColor Cyan
    Write-Host "8:  Remove ALL McAfee from computer (Run 6 first)" -ForegroundColor Cyan
    Write-Host "9:  Check SADR status" -ForegroundColor Cyan
    Write-Host "10: Get bitlocker status" -ForegroundColor Cyan
    Write-Host "11: Turn off BitLocker" -ForegroundColor Cyan
    Write-Host "12: Add computers to Warning Group" -ForegroundColor Cyan
    Write-Host "13: Add computers to Quarantine Group" -ForegroundColor Cyan
    Write-Host "14: Get Computer Image and Last Boot time" -ForegroundColor Cyan
    Write-Host "15: OS Count for Scorecard (No FSE)" -ForegroundColor Cyan
    Write-Host "Q: Press 'Q' to quit" -ForegroundColor Cyan
}
do
{
    Show-Menu
    $selection = Read-Host "Please make a selection." 
    Switch ($selection)
    {
        '1' {
            Write-host 'Remote WakeUp' 
            $Computer = Read-Host "Enter Hostname"
            Write-Host "Please wait..."
            invoke-commandas -ComputerName $Computer -ScriptBlock { & "C:\Program Files\McAfee\Agent\CmdAgent.exe" -p } -AsSystem #Change path as required
            }
        '2' {
            Write-host 'Get Computer AD Groups' 
            $Computer = Read-Host "Enter Hostname"
            Get-ADComputer $Computer -Properties * | select memberof | Format-Custom
            }
        '3' {
            Write-host 'Remove System from HBSS Security Groups' 
            $computer = read-host "Enter Hostname"
            Remove-ADGroupMember -identity '{{AD Group Name Here}}' -Members $computer"$" -Confirm:$false # Warning Banner Security Group from AD
            Remove-ADGroupMember -identity '{{AD Group Name Here}}' -Members $computer"$" -Confirm:$false # Quarantine Security Group from AD
            } 
        '4' {
            Write-Host 'Update AMCore' n
            $Computer = Read-Host "Enter Hostname"
            invoke-commandas -ComputerName $Computer -ScriptBlock { & "C:\Program Files\McAfee\Endpoint Security\Threat Prevention\amcfg.exe" /update } -AsSystem # Update location as needed
            }
        '5' {
            Write-Host 'Get McAfee Info' 
            $Computer = Read-Host "Enter hostname"
            Write-Host "`n"
            Write-Host "McAfee Agent" 
            Write-Host "------------"
            Invoke-Command -ComputerName $Computer -ScriptBlock {Get-ItemPropertyValue -Path HKLM:\SOFTWARE\WOW6432Node\McAfee\Agent -name AgentVersion}
            Write-Host "`n"
            Write-Host "DAT Content Date" 
            Write-Host "----------------"
            Invoke-Command -ComputerName $Computer -ScriptBlock {Get-ItemPropertyValue -Path HKLM:\SOFTWARE\McAfee\AVSolution\DS\DS -name szcontentcreationdate}
            Write-Host "`n"
            }
        '6' {
            Write-Host 'Copy Endpoint Removal Tool to Computer' 
            $Computer = Read-Host "Enter Hostname"
            robocopy C:\NEC\ "\\$computer\C$\NEC\" EndpointProductRemoval_23.11.0.5.exe # Edit path and file name to match your environment
            }
        '7' {
            Write-Host 'Remove ENS from computer' 
            $Computer = Read-Host "Enter Hostname"
            Invoke-CommandAs -ComputerName $computer -ScriptBlock {& cmd /c "C:\NEC\EndpointProductRemoval_23.11.0.5.exe --ACCEPTEULA --ENS --NOREBOOT" } # Edit path and file name to match your environment
            }
        '8' {
            Write-Host 'Remove ALL McAfee from computer' 
            $Computer = Read-Host "Enter Hostname"
            Invoke-CommandAs -ComputerName $computer -ScriptBlock {& cmd /c "C:\NEC\EndpointProductRemoval_23.11.0.5.exe --ACCEPTEULA --ALL --NOREBOOT" } # Edit path and file name to match your environment
            }
        '9' {
            Write-Host 'Check SADR status' # Add or remove SADRs to match your environment
            tnc {{FQDN of SADR}} -p 591
            tnc {{FQDN of SADR}} -p 591
            }
        '10'{
            Write-Host 'Get bitlocker status' 
            $Computer = Read-Host "Enter Hostname"
            manage-bde.exe -cn $Computer -status
            }
        '11'{
            Write-Host 'Turn off BitLocker' 
            $Computer = Read-Host "Enter Hostname"
            manage-bde.exe -cn $Computer -protectors -disable C:
            }
        '12'{
            Write-Host 'Add computers to Warning Group' 
            # Import AD Module
            Write-Host " Importing AD Module... "
            import-module ActiveDirectory
            Start-Sleep -Seconds 2
            Write-Host " Complete "

            # Import list from file
            #$AppendDescription = Read-Host "Please enter the text to be appended to the description"
            Write-Host " *** IMPORTANT: Please add the system names to the file 'C:\Scripts\Move Computer Accounts\Warning.txt' *** " # Edit path and file name to match your environment
            Pause
            $Computers = Get-Content 'C:\Scripts\Move Computer Accounts\Warning.txt' # Edit path and file name to match your environment

            # Move computer and update description
            foreach ($Computer in $Computers) {
            # Add to group   
                $DistinguishedName = (get-ADComputer $Computer).DistinguishedName
                Add-ADGroupMember '{{AD Group Name Here}}' -Members $DistinguishedName  # Should match entry on line 52
                }
            }
        '13'{
            Write-Host 'Add computers to Quarantine Group' 
            # Import AD Module
            Write-Host " Importing AD Module... "
            import-module ActiveDirectory
            Start-Sleep -Seconds 2
            Write-Host " Complete "

            # Import list from file
            #$AppendDescription = Read-Host "Please enter the text to be appended to the description"
            Write-Host " *** IMPORTANT: Please add the system names to the file 'C:\Scripts\Move Computer Accounts\Quarantine.txt' *** " # Edit path and file name to match your environment
            Pause
            $Computers = Get-Content "C:\Scripts\Move Computer Accounts\Quarantine.txt" # Edit path and file name to match your environment

            # Move computer and update description
            foreach ($Computer in $Computers) {

            # Append Description
            #    Get-ADComputer $Computer -Property Description | foreach-object {
            #       $Description = $_.description + " - " +$AppendDescription
            #       Set-ADComputer $Computer -Description $Description
            #    }
    
            # Add to group   
                $DistinguishedName = (get-ADComputer $Computer).DistinguishedName
                Add-ADGroupMember '{{AD Group Name Here}}' -Members $DistinguishedName # Should match entry on line 53
    
                }
            }
        '14'{
            Write-Host 'Get Computer Image and Last Boot time' 
            $computer = Read-Host "Enter Hostname"
            Get-CimInstance -computername $computer -Class CIM_OperatingSystem -ErrorAction continue | Select-Object InstallDate,CSName,LastBootUpTime,LocalDateTime
            }
		'15'{
			Get-ADComputer -searchbase "{AD OU FQDN}}" -Filter {Enabled -eq $True} -Properties operatingSystem | group -Property operatingSystem | Select Name,Count | Sort Name | ft -AutoSize
			}
     }
     pause
 }
 until ($selection -eq 'q')     


        
