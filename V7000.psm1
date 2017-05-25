Function Connect-V7K {
<#
    .SYNOPSIS
        Creates SSH sessions to an IBM V7000.

    .DESCRIPTION
        Once you've created a session, you can use any of the other Cmdlets without specifying which
        system you wish to connect to

        The authentication is done here. If you specify -KeyFile, that will be used. 
        Key file specified. Will override password. If you specify a password and no key, 
        that will be used. If you do not specify a key nor a password, you will be prompted for a password, 
        and you can enter it securely with asterisks displayed in place of the characters you type in.

        The computer name is added to 2 global varibles DefaultV7k and V7KSession.  The first is the default
        V7000 that a command will run against, the later is all V7000's to run the command against 

    .PARAMETER ComputerName
        Required. DNS names or IP addresses for target hosts to establish
        a connection to using the provided username and key/password.
    
    
    .PARAMETER KeyFile
        Optional. Specify the path to a private key file for authenticating.
        Overrides a specified password.

        Please note the KeyFile needs to be in OpenSSH format.
    
    .PARAMETER Credential
        Credtials for logging on to the V7000.  If you are using a KeyFile and have created a Keyfile 
        with no password leave the password blank when entering credentials
    
    .EXAMPLE
        Connect-V7K -ComputerName V7000.domain.com

        This will connect to a V7000, prompting for credentials

    .EXAMPLE
        $Cred = Get-Credentials
        Connect-V7k -ComputerName V7000.domain.com -Credential $Cred

    .EXAMPLE
        Connect-V7K -ComputerName V7000.domain.com -KeyFile C:\Temp\MyKeyFile

        Connects to a V7000 using a KeyFile.  You will be promtped for credentials.  If your KeyFile does not
        have a password, just enter a username.
#>
    [CmdletBinding(DefaultParameterSetName="'Credential")]
    param(
     [Parameter(Position=0,Mandatory=$true)]
     [string] $ComputerName,
     [PSCredential]$Credential,
     [string]$KeyFile
     
    )
    Import-Module Posh-SSH
    If ($Credential -and $KeyFile)
    {
		$Global:DefaultV7K = New-SshSession -ComputerName $ComputerName -Credential $Credential -KeyFile $KeyFile
		$global:KeyFile = $KeyFile
	}
	elseif ($KeyFile)
	{
		$Global:DefaultV7K = New-SshSession -ComputerName $ComputerName -KeyFile $KeyFile
		$global:KeyFile = $KeyFile
	}
	elseIf ($Credential)
	{
		$Global:DefaultV7K = New-SshSession -ComputerName $ComputerName -Credential $Credential
	}
	else
	{
		$Global:DefaultV7K = New-SshSession -ComputerName $ComputerName
	}
	
	
}

function Get-V7KConnection {
<#
    .SYNOPSIS
        Gets existing connections to a V7000.

    .DESCRIPTION
        Returns the SSH session id for existing connections whether connected or disconnected

    .PARAMETER ComputerName
        DNS name or IP addresses for target host.

    .EXAMPLE
        Get-V7KConnection

        Returns the Session ID for the connection defined in $global:DefaultV7K

    .EXAMPLE
        Get-V7KConnection -ComputerName V7000.domain.com

        Returns the session id for the host that matches the ComputerName
    
#>
	param (
		[Parameter()]
		[string]$ComputerName
	)
	
	If (-not $ComputerName)
	{
		$SessionId = $global:DefaultV7K.SessionId
	}
	else
	{
		$SessionId = (Get-SSHSession | where-Object {$_.Host -eq $Computername}).SessionId
	}
    if (-not $SessionId)
    {
        Write-Error "$($ComputerName) is not connected"
        break
    }
	$SessionId
}

Function ConvertFrom-SecureToPlain {
<#
    .SYNOPSIS
        Converts a secure string to plain text

    .DESCRIPTION
        Converts a secure string to plain text.  This is to enable passthru
        credentails to a SSH session

#>
    param( 
        [Parameter(Mandatory=$true)]
        [System.Security.SecureString] $SecurePassword
    )
    
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $private:PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
    $private:PlainTextPassword
}

function Get-V7KReplication {
 <#
  	.SYNOPSIS
		 Returns a concise list or a detailed view of Metro or Global Mirror relationships visible to the clustered system
	
	.DESCRIPTION
		This command returns a concise list or a detailed view of Metro or Global Mirror relationships visible to the system.
        Possible values for the attributes that are displayed as data in the output views.
        Attribute                            Value 
        
        primary                              n/a, master, aux 
        
        state                                consistent_copying, inconsistent_stopped, 
                                             inconsistent_copying, consistent_stopped, 
                                             consistent_synchronized, idling, 
                                             idling_disconnected, inconsistent_disconnected, 
                                             consistent_disconnected 
        
        progress                             0-100, n/a 
        
        cycle_period_seconds                 The minimum period in seconds between multiple cycles 
                                             (integer between 60 and 86400; default is 300). 
        
        cycling_mode                         The type of Global or Metro Mirroring cycling to use: none (default),multi 
        
        freeze time                          The time in YY/MM/DD/HH/MM format. 
        
        status                               online, primary_offline, secondary_offline, 
        
        sync                                 n/a, in_sync, out_of_sync
        
        master_change_vdisk_id               The id of the Vdisk (volume) acting as the master change volume for the relationship (blank if not defined). 
                                             Note: The master_change_vdisk_id field identifies the change volume for the master volume if configured. 
                                             For an intercluster relationship, if the master volume is in the other clustered system (system), 
                                             the master change volume is also in the other system. 
        
        master_change_vdisk_name             The name of the volume acting as the master change volume for the relationship (blank if not defined). 
                                             Note: The master_change_vdisk_name field identifies the change volume for the master volume if configured.
                                             For an intersystem relationship, if the master volume is in the other clustered system (system), 
                                             the master change volume is also in the other system. 
        
        aux_change_vdisk_id                  The id of the volume acting as the auxiliary change volume for the relationship (blank if not defined). 
                                             Note: The aux_change_vdisk_id field identifiesthe change volume for the auxiliary volume, 
                                             if such a volume has been configured. For an intersystem relationship, if the auxiliary volume is in the other system,
                                             the auxiliary change volume is also in the other system. 
        
        aux_change_vdisk_name                The name of the volume acting as the auxiliary change volume for the relationship (blank if not defined). 
                                             Note: The aux_change_vdisk_name field identifies the change volume for the auxiliary volume if configured.
                                             For an intersystem relationship, if the auxiliary volume is in the other system, the auxiliary change volume 
                                             is also in the other system.
                                             
       Note: The names of the Global or Metro Mirror relationships and consistency groups can be blank if the relationship or consistency groups are intersystem 
       and the system partnership is disconnected.

       The sync attribute has a value of in_sync when the contents are synchronized (identical) between volumes. If write operations take place on either
       the primary or secondary volume after a consistent (stopped) or idling state occurs, they will no longer be synchronized.

	
	.EXAMPLE
		Get-V7KReplicationStatus

        Returns a list of all replications.
	
	  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000

    .PARAMETER Id
        Id of an Object

    .PARAMETER Name
        Name of an Object
	
  #>
	[CmdletBinding(DefaultParameterSetName="All")]
	param
	(
		[Parameter(ValueFromPipeline=$True)]
		[Alias('host')]
		[string]$ComputerName,
		[Parameter(Mandatory=$True,ParameterSetName='ID')]
		[int]$Id,
		[Parameter(Mandatory=$True,ParameterSetName='Name')]
		[string]$Name
	)

  	Begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "lsrcrelationship -delim ,"
	    if ($Id) {$cmd += " $Id"}
	    if ($Name) {$cmd += " $Name"}
	}
	
	Process
	{
		if ($Id)
		{
			$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
			If ($info -like 'CMM*')
			{
				Write-Error "$($info)"
				break
			}
			else
			{
				$item = New-Object PSObject
				$lines = $info -split "\s+"
				foreach ($line in $lines)
				{
					$split = $line.Split(",")
					$header = $Split[0]
					if ($Split[0])
					{
						if ($Split[1] -eq $null)
						{
							$Split[1] = ""
						}
						if (($Item | Get-Member).Name -eq $Split[0])
						{
							$item | Add-Member NoteProperty "c$header" $Split[1]
						}
						else
						{
							$item | Add-Member NoteProperty "$header" $Split[1]
						}
					}
					
				}
				$item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
				$Item | ForEach-Object { $_.PSObject.TypeNames.Insert(0, ’SVC.Replication’) }
				
			}
		}
		else
		{
			$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
			$Item = ConvertFrom-Csv $info
			$item | ForEach-Object { Add-Member -InputObject $_ -MemberType NoteProperty -Name ComputerName -Value $ComputerName }
			$Item | ForEach-Object { $_.PSObject.TypeNames.Insert(0, ’SVC.Replication’) }
		}
	}
	End {
    	return $Item
  	}
}

function New-V7KReplication {
  <#
  	.SYNOPSIS
		New replication on a IBM V7000
	
	.DESCRIPTION
		This command creates a new Global or Metro Mirror relationship. A Metro Mirror relationship defines
        the relationship between two volumes: a master volume and an auxiliary volume. This relationship
        persists until it is deleted. The auxiliary virtual disk must be identical in size to the master virtual disk or
        the command fails, and if both volumes are in the same system, they must both be in the same I/O
        group. The master and auxiliary cannot be in an existing relationship. Any defined FlashCopy mappings
        that have the proposed master volume as the target of the FlashCopy mapping must be using the same
        I/O group as the master volume. Any defined FlashCopy mappings that have the proposed auxiliary
        volume as the target of the FlashCopy mapping must be using the same I/O group as the auxiliary
        volume.

        Note: You cannot create a remote copy relationship with this command if the auxiliary volume is an
        active FlashCopy mapping target. The command also returns the new relationship ID.
        
        Metro Mirror relationships use one of the following copy types:
            A Metro Mirror copy ensures that updates are committed to both the primary and secondary volumes
            before sending confirmation of I/O completion to the host application. This ensures that the secondary
            volume is synchronized with the primary volume in the event that a failover operation is performed.
            
        A Global Mirror copy allows the host application to receive confirmation of I/O completion before the
            updates are committed to the secondary volume. If a failover operation is performed, the host
            application must recover and apply any updates that were not committed to the secondary volume.
        
        You can optionally give the relationship a name. The name must be a unique relationship name across
        both systems.
        
        The relationship can optionally be assigned to a consistency group. A consistency group ensures that a
        number of relationships are managed so that, in the event of a disconnection of the relationships, the data
        in all relationships within the group is in a consistent state. This can be important in, for example, a
        database application where data files and log files are stored on separate volumes and consequently are
        managed by separate relationships. In the event of a disaster, the primary and secondary sites might
        become disconnected. As the disconnection occurs and the relationships stop copying data from the
        primary to the secondary site, there is no assurance that updates to the two separate secondary volumes
        will stop in a consistent manner if the relationships that are associated with the volumes are not in a
        consistency group.
        
        For proper database operation, it is important that updates to the log files and the database data are
        made in a consistent and orderly fashion. It is crucial in this example that the log file volume and the
        data volume at the secondary site are in a consistent state. This can be achieved by putting the
        relationships that are associated with these volumes into a consistency group. Both Metro Mirror and
        Global Mirror processing ensure that updates to both volumes at the secondary site are stopped, leaving
        a consistent image based on the updates that occurred at the primary site.
        If you specify a consistency group, both the group and the relationship must have been created using the
        same master system and the same auxiliary system. The relationship must not be a part of another
        consistency group. If the consistency group is empty, it acquires the type of the first relationship that is
        added to it. Therefore, each subsequent relationship that you add to the consistency group must have the
        same type.
        If the consistency group is not empty, the consistency group and the relationship must be in the same
        state. If the consistency group is empty, it acquires the state of the first relationship that is added to it. If
        the state has an assigned copy direction, the direction of the consistency group and the relationship must
        match that direction.
        If you do not specify a consistency group, a stand-alone relationship is created.
        
        If you specify the -sync parameter, the master and auxiliary virtual disks contain identical data at the
        point when the relationship is created. You must ensure that the auxiliary is created to match the master
        and that no data movement occurs to either virtual disk before you issue the mkrcrelationship
        command.
        
        If you specify the -global parameter, a Global Mirror relationship is created. Otherwise, a Metro Mirror
        relationship is created instead.
        
        A volume specified on the master and aux parameters must be used in a non-existing relationship. This
        means it cannot be the master or auxiliary volume of an existing relationship.
	
	.EXAMPLE
		New-V7kReplication -Master 84 -Aux 84 -Cluster
	
	.EXAMPLE
		New-V7kReplication -Master 84 -Aux 84 -Cluster -Sync -Global

    .EXAMPLE
			  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000

    .Notes
        Cluster must be the target cluster.  Can be retreived user Get-V7KPartnership
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName,
    [Parameter(Mandatory=$True)]
    [string]$Master,
    [Parameter(Mandatory=$True)]
    [string]$Aux,
    [string]$NewName,
    [string]$ConsistGrp,
    [switch]$Sync,
    [switch]$Global,
    [Parameter()]
    [ValidateSet('none','multi')]
    [string]$CyclingMode
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$Partner = Get-V7KPartnership -ComputerName $ComputerName | Where-Object {$_.location -eq 'remote'}
	    $Cluster = $Partner.ID
	    $cmd = "mkrcrelationship -master $Master -aux $Aux -cluster $Cluster"
	    if ($NewName) {$cmd += " -name $NewName"}
	    if ($ConsistGrp) {$cmd += " -consistgrp $ConsistGrp"}
	    if ($Sync) {$cmd += " -sync"}
	    if ($Global) {$cmd += " -global"}
	    if ($CyclingMode) {$cmd += " -cyclingmode $CyclingMode"}

  }

  process {
         
        
        Write-Verbose "$($cmd)"
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        If ($info -like 'CMM*') {
            Write-Error "$($info)"
        }
        Write-Verbose "$($info)"
  }
  
}

function Remove-V7KReplication {
  <#
  	.SYNOPSIS
		Deletes a remote copy on a IBM V7000
	
	.DESCRIPTION
		This command deletes the relationship that is specified. Deleting a relationship only deletes 
        the logical relationship between the two virtual disks; it does not affect the virtual disks themselves.
        If the relationship is disconnected at the time that the command is issued, the relationship is only deleted
        on the clustered system (system) where the command is being run. When the systems reconnect, the
        relationship is automatically deleted on the other system. Alternatively, if the systems are disconnected
        and if you still want to remove the relationship on both systems, you can issue the rmrcrelationship
        command independently on both of the systems.
        If Global Mirror relationship using multicycling mode, and you attempt to delete the relationship without
        enabling access first, specifying rmrcrelationship might fail with an error because the relationship does
        not currently have a fully consistent secondary volume. Specifying -force overrides this test. This is not
        the default behavior, and you can quiesce and delete the relationship in order to use the secondary
        volume's data immediately. If the map is still performing the background copy to migrate data from the
        change volume to the secondary volume, the changed volume and associated FlashCopy mappings
        remain defined when rmrcrelationship completes. The FlashCopy mappings are deleted after the
        background copy completes, and the change volume becomes unusable again.
        If you delete an inconsistent relationship, the secondary virtual disk becomes accessible even though it is
        still inconsistent. This is the one case in which Metro or Global Mirror does not inhibit access to
        inconsistent data.
	
	.EXAMPLE
		Remove-V7kReplication -Id 84
	
	.EXAMPLE
		Remove-V7kReplication -Id 84 -Force

		  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True)]
    [string]$Id,
    [switch]$Force
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "rmrcrelationship"
    if ($Force) {$cmd += " -force"}
    $cmd += " $Id"
  }

  process {
         
        Write-Verbose "$($cmd)"
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        If ($info -like 'CMM*') {
            Write-Error "$($info)"
        }
        Write-Verbose "$($info)"
  }
  
}

function Start-V7KReplication {
  <#
  	.SYNOPSIS
		Start replication on a IBM V7000
	
	.DESCRIPTION
		Start replication on a IBM V7000
	
	.EXAMPLE
		Get-V7KReplication | Start-V7000Replication

        Starts all replications from the default connected V7000
	
	.EXAMPLE
		Get-V7KReplication -State consistent_stopped | Start-V7000Replication

        Starts all replications where the state of the replication is consistent_stopped

    .EXAMPLE
		$relationship = Get-V7KReplication -State consistent_stopped
        Start-V7000Replication -Relationship $relationship

    .EXAMPLE
		$relationship = Get-V7KReplication -State consistent_stopped
        $relationship | Start-V7000Replication
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
    $Relationship
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	
	process {
    $relationship | ForEach-Object {
        $cmd = "startrcrelationship -force $($_.Name)"
        Write-Verbose "Starting $($_.Name)"
        $info = Invoke-SSHCommand -SessionId $sessionid -Command $cmd
    }
  }
}

function Stop-V7KReplication {
  <#
  	.SYNOPSIS
		Stops replication on a IBM V7000
	
	.DESCRIPTION
		Stops replication on a IBM V7000
	
	.EXAMPLE
		Get-V7KReplication | Stop-V7000Replication
	
	.EXAMPLE
		Get-V7KReplication -State consistent_synchronized | Stop-V7000Replication

        Stops all replications who state is consistent_syncronized
   
   .EXAMPLE
		$relationship = Get-V7KReplication -State consistent_synchronized
        Stop-V7000Replication -Relationship $relationship

    .EXAMPLE
		$relationship = Get-V7KReplication -State consistent_synchronized
        $relationship | Stop-V7000Replication
         
	.PARAMETER Relationship
		The replication relationship.  This can be got from Get-V7KReplication
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
    $Relationship
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	
	process {
    $relationship | ForEach-Object {
        $cmd = "stoprcrelationship $($_.Name)"
        Write-Verbose "Stopping $($_.Name)"
			$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
			$info
    }
  }
}

function Switch-V7KReplication {
  <#
  	.SYNOPSIS
		Switches the direction of a replication on a IBM V7000
	
	.DESCRIPTION
		Switches the direction of a replication on a IBM V7000
	
	.EXAMPLE
		Get-V7KReplication | Switch-V7KReplication -Primary aux

        Switches all replications to the aux copy
	
	.EXAMPLE
		Get-V7KReplication -Id 84 | Switch-V7KReplication -Primary aux

        Switches the replication with the Id of 84 to the aux copy
   
	.PARAMETER Relationship
		The replication relationship.  This can be got from Get-V7KReplication
	
  #>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)]
		$Relationship,
		[Parameter(Mandatory = $True)]
		[ValidateSet('master','aux')]
		[string]$Primary
	)
	
	begin
	{
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	
	process
	{
		$cmd = "switchrcrelationship -primary $Primary $($_.id)"
		Write-Verbose "Switching $($_.id)"
		$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
		$info
		
	}
}

function Get-V7KMDisk {
  <#
  	.SYNOPSIS
		The lsmdisk command returns a concise list or a detailed view of managed disks (MDisks) visible to the cluster. 
        It can also list detailed information about a single MDisk. 
	
	.DESCRIPTION
		This command returns a concise list or a detailed view of MDisks visible to the cluster. 
        Attribute Values status v online v offline v excluded v degraded_paths v degraded_ports v degraded (applies only to internal MDisks) mode unmanaged, managed, image, array quorum_index 0, 1, 2, or blank if the MDisk is not being used as a quorum disk block_size 512, 524 bytes in each block of storage ctrl_type 4, 6, where 6 is a solid-state drive (SSD) attached inside a node and 4 is any other device tier The tier this MDisk has been assigned to by auto-detection (for internal arrays) or by the user: v generic_ssd v generic_hdd (the default value for newly discovered or external MDisk) Note: You can change this value using the chmdisk command. raid_status v offline - the array is offline on all nodes v degraded - the array has deconfigured or offline members; the array is not fully redundant v syncing - array members are all online, the array is syncing parity or mirrors to achieve redundancy v initting - array members are all online, the array is initializing; the array is fully redundant v online - array members are all online, and the array is fully redundant raid_level The RAID level of the array (RAID0, RAID1, RAID5, RAID6, RAID10).
Chapter 17. Information commands 269
Table 34. MDisk output (continued) Attribute Values redundancy The number of how many member disks can fail before the array fails. strip_size The strip size of the array (in KB). spare_goal The number of spares that the array members should be protected by. spare_protection_min The minimum number of spares that an array member is protected by. balanced Describes if the array is balanced to its spare goals: v exact: all populated members have exact capability match, exact location match v yes: all populated members have at least exact capability match, exact chain, or different enclosure or slot v no: anything else
Note: The automatic discovery performed by the cluster does not write anything to an unmanaged MDisk. It is only when you add an MDisk to an MDisk group (storage pool), or use an MDisk to create an image mode VDisk (volume), that the system uses the storage.
To see which MDisks are available, issue the detectmdisk command to manually rescan the Fibre Channel network for any new MDisks. Issue the lsmdiskcandidate command to show the unmanaged MDisks. These MDisks have not been assigned to an MDisk group (storage pool).
Notes: 1. A SAN Volume Controller connection from a node or node canister port to a storage controller port for a single MDisk is a path. The Mdisk path_count value is the number of paths currently being used to submit input/output (I/O) to this MDisk. 2. The MDisk max_path_count value is the highest value path_count has reached since the MDisk was last fully online. 3. The preferred_WWPN is one of the World Wide Port Names (WWPNs) the storage controller has specified as a preferred WWPN. If the controller has nothing specified, this is a blank field. 4. The active_WWPN indicates the WWPN of the storage controller port currently being used for I/O. a. If no storage controller ports are available for I/O, this is a blank field. b. If multiple controller ports are actively being used for I/O, this field's value is many.
The following define the status fields: Online The MDisk is online and available. Degraded (Internal MDisks only) The array has members that are degraded, or the raid_status is degraded. Degraded ports There are one or more MDisk port errors. Degraded paths One or more paths to the MDisk have been lost; the MDisk is not online to every node in the cluster. Offline All paths to the MDisk are lost. Excluded The MDisk is excluded from use by the cluster; the MDisk port error count exceeded the threshold.

	
	.EXAMPLE
		Get-V7000System -ComputerName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000
	
  #>
   [CmdletBinding(DefaultParameterSetName="All")]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True,ParameterSetName='ID')]
    [int]$Id,
    [Parameter(Mandatory=$True,ParameterSetName='Name')]
    [string]$Name
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$defaultProperties = @('ID','Name','Status','mdisk_grp_name','Capacity')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    $cmd = "lsmdisk -delim ,"
    if ($Id) {$cmd += " $Id"}
    if ($Name) {$cmd += " $Name"}
  }

  process {
    if ($Id) {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $item = New-Object PSObject
        $lines = $info -split "\s+"
        foreach ($line in $lines)
        {
            $split = $line.Split(",")                
            $header = $Split[0]
            if ($Split[0]) {
                if ($Split[1] -eq $null) {
                    $Split[1] = ""
                }
                if (($Item | Get-Member).Name -eq $Split[0]) {
                    $item | Add-Member NoteProperty "c$header" $Split[1]
                }
                else {
                    $item | Add-Member NoteProperty "$header" $Split[1]
                }
            }
            
        }
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
        $Item | Add-Member MemberSet PSStandardMembers $PSStandardMembers
     }
    else {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $Item = ConvertFrom-Csv $info
        $item | ForEach-Object {Add-Member -InputObject $_ -MemberType NoteProperty -Name ComputerName -Value $ComputerName}
        $Item | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    }


  }
  end {
    $status | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    return $status
  }
}

function Get-V7KMDiskGroup {
  <#
  	.SYNOPSIS
		Gets the mDisk groups of a IBM V7000
	
	.DESCRIPTION
		Gets the mDisk groups of a IBM V7000
	
	.EXAMPLE
		Get-V7000DiskGroup -ComputerName 172.0.0.10
	
	.PARAMETER ComputerName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding(DefaultParameterSetName="All")]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True,ParameterSetName='ID')]
    [int]$Id,
    [Parameter(Mandatory=$True,ParameterSetName='Name')]
    [string]$Name,
    [switch]$Bytes

  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$defaultProperties = @('ID','Name','free_capacity','Virtual_Capacity')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    $cmd = "lsmdiskgrp -delim ,"
    if ($Bytes) {$cmd += " -bytes"}
    if ($Id) {$cmd += " $Id"}
    if ($Name) {$cmd += " $Name"}
  }

  process {
   if ($Id) {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $item = New-Object PSObject
        $lines = $info -split "\s+"
        foreach ($line in $lines)
        {
            $split = $line.Split(",")                
            $header = $Split[0]
            if ($Split[0]) {
                if ($Split[1] -eq $null) {
                    $Split[1] = ""
                }
                if (($Item | Get-Member).Name -eq $Split[0]) {
                    $item | Add-Member NoteProperty "c$header" $Split[1]
                }
                else {
                    $item | Add-Member NoteProperty "$header" $Split[1]
                }
            }
            
        }
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
        $Item | Add-Member MemberSet PSStandardMembers $PSStandardMembers
     }
    else {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $Item = ConvertFrom-Csv $info
        $item | ForEach-Object {Add-Member -InputObject $_ -MemberType NoteProperty -Name ComputerName -Value $ComputerName}
        $Item | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    }
   
  }
  end {
    return $Item
    }
}

function Get-V7KIOGroup {
  <#
  	.SYNOPSIS
		Gets a IBM V7000 IO Group
	
	.DESCRIPTION
		Gets a IBM V7000 IO Group
	
	.EXAMPLE
		Get-V7000System -ComputerName 172.0.0.10
	
    .PARAMETER ComputerName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding(DefaultParameterSetName="All")]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True,ParameterSetName='ID')]
    [int]$Id,
    [Parameter(Mandatory=$True,ParameterSetName='Name')]
    [string]$Name

  )
  Begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	process {
   if ($Id) {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $item = New-Object PSObject
        $lines = $info -split "\s+"
        foreach ($line in $lines)
        {
            $split = $line.Split(",")                
            $header = $Split[0]
            if ($Split[0]) {
                if ($Split[1] -eq $null) {
                    $Split[1] = ""
                }
                if (($Item | Get-Member).Name -eq $Split[0]) {
                    $item | Add-Member NoteProperty "c$header" $Split[1]
                }
                else {
                    $item | Add-Member NoteProperty "$header" $Split[1]
                }
            }
            
        }
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
        $Item | Add-Member MemberSet PSStandardMembers $PSStandardMembers
     }
    else {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $Item = ConvertFrom-Csv $info
        $item | ForEach-Object {Add-Member -InputObject $_ -MemberType NoteProperty -Name ComputerName -Value $ComputerName}
        $Item | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    }
   
  }
  end {
    return $Item
  }
}

function Get-V7KSystem {
  <#
  	.SYNOPSIS
		Gets the system information of a IBM V7000
	
	.DESCRIPTION
		Gets the system information for an IBM V7000, this includes capacity info
        code level and ip address
	
	.EXAMPLE
		Get-V7000System -ComputerName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "lssystem -delim ,"
  }

  process {
    $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
    $status = ConvertFrom-Csv $info
  }
  end {
    return $status
  }
}
   
function Get-V7KVDisk {
  <#
  	.SYNOPSIS
		Gets the VDisks of a IBM V7000
	
	.DESCRIPTION
		Gets the system information for an IBM V7000, this includes capacity info
        code level and ip address
        Due to the way information is returned when querying a single vdisk, the NoteProperty
        for the copy is preapended with a c. i.e status becomes cstatus
	
	.EXAMPLE
		Get-V7000System -HostName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding(DefaultParameterSetName="All")]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True,ParameterSetName='ID',Position=0)]
    [int]$Id,
    [Parameter(Mandatory=$True,ParameterSetName='Name')]
    [string]$Filter,
    [switch]$Bytes

  )

	begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		#$SessionId = $Global:DefaultV7K.SessionID
	    $cmd = "lsvdisk -delim ,"
	    if ($Bytes) {$cmd += " -bytes"}
	    if ($Id) {$cmd += " -filtervalue id=$Id"}
		if ($Filter) { $cmd += " -filtervalue $Filter" }
	}
	
	process {
 
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $Item = ConvertFrom-Csv $info
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
        $Item | ForEach-Object {$_.PSObject.TypeNames.Insert(0,’SVC.vDisk’)}

  
  }

  end {
    
    return $Item
  }
} 

function Get-V7KVDiskById {
  <#
  	.SYNOPSIS
		Gets the VDisks of a IBM V7000
	
	.DESCRIPTION
		Gets the system information for an IBM V7000, this includes capacity info
        code level and ip address
        Due to the way information is returned when querying a single vdisk, the NoteProperty
        for the copy is preapended with a c. i.e status becomes cstatus
	
	.EXAMPLE
		Get-V7000System -HostName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding(DefaultParameterSetName="All")]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True,ParameterSetName='ID',Position=0)]
    [int[]]$Id,
    [Parameter(Mandatory=$True,ParameterSetName='Name')]
    [string]$Filter,
    [switch]$Bytes

  )

	begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		#$SessionId = $Global:DefaultV7K.SessionID
	    $cmd = "lsvdisk -delim ,"
	    if ($Bytes) {$cmd += " -bytes"}
	    $orgcmd = $cmd
	}
	
	process {
 
        $cmd += " $Id"
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $item = New-Object PSObject
        $lines = $info -split "\s+"
        foreach ($line in $lines)
        {
            $split = $line.Split(",")                
            $header = $Split[0]
            if ($Split[0]) {
                if ($Split[1] -eq $null) {
                    $Split[1] = ""
                }
                if (($Item | Get-Member).Name -eq $Split[0]) {
                    $item | Add-Member NoteProperty "$header$Split[1]" $Split[1]
                }
                
            }
            
        }
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
        $Item | ForEach-Object {$_.PSObject.TypeNames.Insert(0,’SVC.vDisk’)}

  
  }

  end {
    
    return $Item
  }
} 

function New-V7KVDisk {
  <#
  	.SYNOPSIS
		Creates a new vdisks on an IBM V7000
	
	.DESCRIPTION
		Creates a new vdisks on an IBM V7000
	
	.EXAMPLE
		New-V7000VDisk New-V7000VDisk -ComputerName 172.0.0.1 -Mdiskgrp SAS_Pool_1 -name C_SAS_Pool_1_NHSWL -Size 2500 -Unit gb
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True)]
    [string]$Mdiskgrp,
    [Parameter()]
    [int]$IOgrp = 0, #need to add error checking
    [Parameter(Mandatory=$True)]
    [string]$name,
    [Parameter()]
    [ValidateSet('readwrite','none')]
    [string]$cache,
    [Parameter(Mandatory=$True)]
    [double]$Size,
    [Parameter()]
    [string]$Rsize = "2%",
    [Parameter()]
    [ValidateSet('b','kb','mb','gb','tb','pb',IgnoreCase = $false)]
    [string]$Unit = "mb" ,
    [Parameter()]
    [string]$Warning = "80%",
    [Parameter()]
    [ValidateSet('32','64','128','256')]
    [int]$GrainSize = 256,
    [Parameter()]
    [ValidateRange(1,2)]
    [int]$Copies,
    [Parameter()]
    [ValidateRange(0,100)]
    [int]$syncrate,
    [Parameter()]
    [ValidateSet('seq','striped','image')]
    [string]$vtype,
    [Parameter()]
    [switch]$Autoexpand,
    [Parameter()]
    [switch]$Import,
    [Parameter()]
    [switch]$createsync,
    [Parameter()]
    [switch]$FormatDisk,
    [Parameter()]
    [switch]$Compressed,
    [Parameter()]
    [ValidateSet('latency','redundancy')]
    [string]$mirrorwritepriority,
    [Parameter()]
    [string]$node, #needs error checking
    [Parameter()]
    [string]$mdisk,  #needs error checking
    [Parameter()]
    [string]$Accessiogrp,  #needs error checking
    [Parameter()]
    [ValidateSet('generic_ssd','generic_hhd')]
    [string]$tier,
    [Parameter()]
    [ValidateSet('on','off')]
    [string]$easytier,
    [Parameter()]
    [int]$udid   #needs error checking

    
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "mkvdisk"
    if ($Import) {$cmd += " -import"}
    if ($createsync) {$cmd += " -createsync"}
    if ($FormatDisk) {$cmd += " -fmtdisk"}
    if ($Compressed) {$cmd += " -compressed"}
    if ($mirrorwritepriority)  {$cmd += " -mirrorwritepriority $mirrorwritepriority"}
    if ($node) {$cmd += " -node $node"}  #needs error checking
    if ($mdisk) {$cmd += " -mdisk $mdisk"}  #needs error checking
    if ($Accessiogrp) {$cmd += " -Accessiogrp $Accessiogrp"}  #needs error checking
    if ($tier) {$cmd += " -tier $tier"}
    if ($udid) {$cmd += " -udid $udid"}   #needs error checking
    if ($cache) {$cmd += " -cache $cache"}
    if ($copies) {$cmd += " -copies $copies"}
    if ($syncrate) {$cmd += " -syncrate $syncrate"}
    if ($vtype) {$cmd += " -vtype $vtype"}

    $cmd += " -autoexpand -grainsize $grainsize -iogrp $iogrp -mdiskgrp $mdiskgrp -name $name -rsize $rsize -size $size -unit $unit -warning $Warning"
    
    Write-Verbose $($cmd)
    
  }

  process {
    try {
        $ErrorActionPreference = "Stop"
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $info
    }
    catch [System.Exception]{
        
        Write-Error $($_.Exception.Message)
        $ErrorActionPreference = "Continue"
    }
    

  }

}   

function Set-V7KVDisk {
  <#
  	.SYNOPSIS
		The Set-V7KVDisk command modifies the properties of a volume, such as the disk name, I/O governing rate,
        or unit number
	
	.DESCRIPTION
		The Set-V7KVDisk command modifies a single property of a volume. To change the volume name and modify
        the synchronization rate, for example, you must issue the command twice.
        
        Note: If the volume is offline, use one of the recovervdisk commands to recover the volume and bring it
        back online.
        
        Important: To change the caching I/O group for a volume, use the movevdisk command.
        You can specify a new name or label. You can use the new name subsequently to refer to the volume.
        You can set a limit on the amount of I/O transactions that is accepted for this volume. It is set in terms of
        I/Os per second or MBs per second. By default, no I/O governing rate is set when a volume is created.
        
        Attention: All capacities, including changes, must be in multiples of 512 bytes. An error occurs if you
        specify a capacity that is not a multiple of 512, which can only happen when byte units (-b) are used. The
        default capacity is in MB.
        When the volume is created, there is no throttling applied to it. Using the -rate parameter can change
        this. To change the volume back to an unthrottled state, specify 0 (zero) with the -rate parameter.
        
        Table 63 provides the relationship of the rate value to the data copied per second.
        Table 63. Relationship between the rate value and the data copied per second
        User-specified rate attribute value Data copied/sec
        1 - 10 128 KB
        11 - 20 256 KB
        21 - 30 512 KB
        31 - 40 1 MB
        41 - 50 2 MB
        51 - 60 4 MB
        61 - 70 8 MB
        71 - 80 16 MB
        81 - 90 32 MB
        91 - 100 64 MB
	
	.EXAMPLE
		Set-V7KVDisk -ComputerName 172.0.0.1 -NewName vDisk22 -Id 2
	
	.EXAMPLE
		Set-V7KVDisk -ComputerName 172.0.0.1 -AutoExpand on -Id 2
	  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000

    .PARAMETER NewName
        (Optional) Specifies a new name to assign to the volume. You cannot use this parameter with the
        Rate or Udid parameters. This parameter is required if you do not use the Rrateor Udid parameters.

    .PARAMETER Cache
        (Optional) Specifies the caching options for the volume. Valid entries are readwrite, to enable the
        cache for the volume, or none, to disable the cache mode for the volume.

    .PARAMETER Force
        (Optional) The force parameter can only be used for changing the I/O group of a volume or the
        caching mode. Use the force parameter with the iogrp parameter to force the volume to be removed
        from an I/O group. Use the force parameter with the cache parameter to specify that you want the
        system to change the cache mode of the volume even if the I/O group is offline. This option
        overrides the cache flush mechanism.

        Attention: If the force parameter is used for changing the caching mode, the contents of the cache
        are discarded and the volume might be corrupted by the loss of the cached data. This could occur if
        the system is able to destage all write data from the cache or not. The force parameter should be
        used with caution.
        Important: Using the force parameter might result in a loss of access. Use it only under the direction
        of the IBM Support Center.

    .PARAMETER Rate
        (Optional) Specifies the I/O governing rate for the volume, which caps the amount of I/O that is
        accepted. The default throttle_rate units are I/Os. To change the throttle_rate units to megabytes per
        second (MBps), specify the -unitmb parameter. The governing rate for a volume can be specified by
        I/Os or by MBps, but not both. However, you can set the rate to I/Os for some volumes and to
        MBps for others.
        You cannot use this parameter with the NewName or Uuid parameters.

    .PARAMETER UnitMB
        See Rate

    .PARAMETER Udid
        (Optional) Specifies the unit number (udid) for the disk. The vdisk_udid is an identifier that is
        required to support OpenVMS hosts; no other systems use this parameter. Valid options are a decimal
        number from 0 to 32 767 or a hexadecimal number from 0 to 0x7FFF. A hexadecimal number must be
        preceded by 0x (for example, 0x1234). If you do not use the -udid parameter, the default udid is 0.
        You cannot use this parameter with the -name or -udid parameters.

    .PARAMETER Warning
        (Optional) Generates a warning when the used disk capacity on the space-efficient copy first exceeds
        the specified threshold. You can specify a disk_size integer, which defaults to MBs unless the -unit
        parameter is specified; or you can specify a disk_size%, which is a percentage of the volume size. To
        disable warnings, specify 0 or 0%.

    .PARAMETER unit b | kb | mb | gb | tb | pb
        (Optional) Specifies the data units to use for the -warning disk_size parameter. The default unit value
        is MB.

    .PARAMETER Autoexpand on | off
        (Optional) Specifies whether space-efficient volume copies automatically expand their real capacities
        by allocating new extents from their managed disk group. To use this parameter, the volume must be
        space-efficient.

    .PARAMETER Copy Id
        (Optional) Specifies the copy to apply the changes to. You must specify this parameter with the
        -autoexpand or -warning parameter. The -copy parameter is required if the specified volume is
        mirrored and only one volume copy is space-efficient. If both copies are space-efficient and the -copy
        parameter is not specified, the specified -autoexpand or -warning parameter is set on both copies.

    .PARAMETER Primary
        (Optional) Specifies the primary copy. Changing the primary copy only takes effect when the new
        primary copy is online and synchronized. If the new primary is online and synchronized when the
        command is issued, the change takes effect immediately.

    .PARAMETER Syncrate
        (Optional) Specifies the copy synchronization rate. A value of zero (0) prevents synchronization. The
        default value is 50. See Table 63 on page 475 for the supported -syncrate values and their
        corresponding rates.

    .PARAMETER easytier on | off
        (Optional) Enables or disables the IBM System Storage Easy Tier function.

    .PARAMETER mirrorwritepriority
        (Optional) Specifies how to configure the mirror write algorithm priority. A change to the mirror
        write priority is reflected in the volume's view immediately and in the volume's behavior after all
        prior input and output (I/O) completes.
        1. Choosing latency means a copy that is slow to respond to a write I/O becomes unsynchronized,
        and the write I/O completes if the other copy successfully writes the data
        2. Choosing redundancy means a copy that is slow to respond to a write I/O synchronizes
        completion of the write I/O with the completion of the slower I/O in order to maintain
        synchronization.
        3. If not specified, the current value is unchanged.

    .PARAMETER Id
        (Required) Specifies the volume to modify, either by ID or by name.
	
  #>
  [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High',DefaultParameterSetName="All")]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [string]$NewName,
    [Parameter(ParameterSetName='Cache')]
    [ValidateSet('readwrite','none')]
    [string]$Cache,
    [Parameter(ParameterSetName='Cache')]
    [switch]$Force,
    [Parameter(ParameterSetName='Rate')]
    [string]$Rate,
    [Parameter(ParameterSetName='Rate')]
    [switch]$UnitMB,
    [string]$Udid,
    [string]$Warning,
    [ValidateSet('b','kb','mb','gb','tb','pb',IgnoreCase = $false)]
    [string]$Unit = "mb",
    [ValidateSet('on','off')]
    [string]$Autoexpand,
    [string]$Copy,
    [string]$Primary,
    [string]$Syncrate,
    [ValidateSet('on','off')]
    [string]$Easytier,
    [ValidateSet('latency','redundancy')]
    [string]$MirrorWRitePriority,
    [Parameter(Mandatory=$True)]
    [string]$Id


    
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "chvdisk"
    if ($NewName) {$cmd += " -name $NewName"}
    if ($Cache) {$cmd += " -cache $Cache"}
    if ($Force) {$cmd += " -force"}
    if ($Rate) {$cmd += " -rate $Rate"}
    if ($UnitMB)  {$cmd += " -unitmb $UnitMB"}
    if ($Udid) {$cmd += " -uuid $Udid"}  #needs error checking
    if ($Warning) {$cmd += " -warning $Warning"}  #needs error checking
    if ($Unit) {$cmd += " -unit $Unit"}  #needs error checking
    if ($Autoexpand) {$cmd += " -autoexpand $Autoexpand"}
    if ($Copy) {$cmd += " -copy $Copy"}   #needs error checking
    if ($Primary) {$cmd += " -primary $Primary"}
    if ($Syncrate) {$cmd += " -syncrate $Syncrate"}
    if ($Easytier) {$cmd += " -easytier $Easytier"}
    if ($MirrorWRitePriority) {$cmd += " -mirrorwritepriority $MirrorWRitePriority"}
    $cmd += " $Id"
        
    Write-Verbose $($cmd)
    
  }

  process {
    try {
        $ErrorActionPreference = "Stop"
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $info
    }
    catch [System.Exception]{
        
        Write-Error $($_.Exception.Message)
        $ErrorActionPreference = "Continue"
    }
    

  }

}

function Remove-V7KVDisk {
  <#
  	.SYNOPSIS
		Removes a VDisks on an IBM V7000
	
	.DESCRIPTION
		This command deletes an existing managed mode volume or an existing image mode volume. The extents that 
        made up this volume are returned to the pool of free extents that are available on the managed disk group, 
        if the volume is in managed mode.

        ATTENTION: Any data that was on the volume is lost. Before you issue this command, ensure that the 
        volume (and any data that resides on it) is no longer required. 
	
	.EXAMPLE
		Remove-V7000VDisk -ComputerName 172.0.0.10 -Id 2
	
	.EXAMPLE
		Get-V7000VDisk -ComputerName 172.0.0.10 -Id 2 | Remove-V7000VDisk

	.EXAMPLE
		$vdisk = Get-V7000VDisk -ComputerName 172.0.0.10  | Where-Object {$_.Name -like '*Test*'}
        Remove-V7000VDisk -Vdisk $vdisk

        This example removes all the vDisk that contain the word Test in thier name
	  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000

    .PARAMETER Id
        Id if the vDisk to be deleted

    .PARAMETER Vdisk
        A vDisk object. This can be used to pipe output from Get-V7000VDisk

    .PARAMETER Force
         Deletes the specified volume, even if mappings still exist between this volume and one or more hosts. 
         This parameter deletes any host-to-volume mappings and any FlashCopy mappings that exist for this volume. 
         If the -force deletion of a volume causes dependent mappings to be stopped, any target volumes for those 
         mappings that are in Metro Mirror or Global Mirror relationships are also stopped. The dependent mappings 
         can be identified by using the Get-V7000VDiskDependentMaps command on the volume that you want to delete. 
	
  #>
	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High',DefaultParameterSetName="Obj")]
	param
	(
		[Parameter()]
		[Alias('host')]
		[string]$ComputerName = $Global:DefaultV7K.Host,
		[Parameter(ParameterSetName='ID')]
		[int[]]$Id,
		[Parameter(ParameterSetName='Name')]
		[string[]]$Name,
		[Parameter(ValueFromPipeline = $True, ParameterSetName = 'Obj')]
		[PSCustomObject]$Vdisk,
		[switch]$Force
	)

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		
	}
	
	process {
		if ($Name)
		{
			$cmd = "rmvdisk"
			if ($Force) { $cmd += " -force" }
			foreach ($Disk in $Name)
			{
				$cmd += " $Disk"
				$Msg = $Disk
				Write-Verbose "Name is $($Disk)"
				Write-Verbose "Command is $($cmd)"
				if ($pscmdlet.ShouldProcess($Msg))
				{
					$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
					Write-Verbose "$($info)"
				}
			}
		}
		if ($Id)
		{
			$cmd = "rmvdisk"
			if ($Force) { $cmd += " -force" }
			foreach ($Disk in $Id)
			{
				$cmd += " $Disk"
				$Msg = $Disk
				Write-Verbose "ID is $($Disk)"
				Write-Verbose "Command is $($cmd)"
				if ($pscmdlet.ShouldProcess($Msg))
				{
					$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
					Write-Verbose "$($info)"
				}
			}
		}
		if ($Vdisk)
		{
			$cmd = "rmvdisk"
			if ($Force) { $cmd += " -force" }
			$cmd += " $($_.Id)"
			$Msg = "$($_.Id)"
			Write-Verbose "Object ID is $($_.Id)"
			Write-Verbose "Command is $($cmd)"
			if ($pscmdlet.ShouldProcess($Msg))
			{
				$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
				Write-Verbose "$($info)"
			}
		}
		
	}
	
	end {

  }
} 

function Get-V7KHost {
  <#
  	.SYNOPSIS
		Gets the connected Hosts to a IBM V7000
	
	.DESCRIPTION
		Gets the connected hosts to a IBM V7000
	
	.EXAMPLE
		Get-V7000System
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding(DefaultParameterSetName="All")]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True,ParameterSetName='ID')]
    [int]$Id,
    [Parameter(Mandatory=$True,ParameterSetName='Name')]
    [string]$Name

  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "lshost -delim ,"
    if ($Id) {$cmd += " $Id"}
  }

  process {
    if ($Id) {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $item = New-Object PSObject
        $lines = $info -split "\s+"
        foreach ($line in $lines)
        {
            $split = $line.Split(",")                
            $header = $Split[0]
            if ($Split[0]) {
                if ($Split[1] -eq $null) {
                    $Split[1] = ""
                }
                if (($Item | Get-Member).Name -eq $Split[0]) {
                    $item | Add-Member NoteProperty "c$header" $Split[1]
                }
                else {
                    $item | Add-Member NoteProperty "$header" $Split[1]
                }
            }
            
        }
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
     }
    else {
        $defaultProperties = @('Id',‘Name’,'port_count','status')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $Item = ConvertFrom-Csv $info
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
        $Item | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    }
    
  }

  end {
    
    return $Item
  }
} 

function Get-V7KVDiskHostMap {
 <#
  	.SYNOPSIS
		Gets vdisk Hosts mappings on an IBM V7000
	
	.DESCRIPTION
		Gets vdisk to Hosts mappings on an IBM V7000
	
	.EXAMPLE
		Get-V7KVDiskHostMap -Id 1
	
	.EXAMPLE
		Get-V7KvDisk -Id 1 | Get-V7KVDiskHostMap
	
	.PARAMETER ComputerName
		IP address or DNS name of the V7000
	
  #>
	[CmdletBinding( DefaultParameterSetName="Obj")]
	param
	(
		[Parameter()]
		[Alias('host')]
		[string]$ComputerName = $Global:DefaultV7K.Host,
		[Parameter(Mandatory = $True, ParameterSetName = 'ID', Position = 0)]
		[int[]]$Id,
		[Parameter(Mandatory = $True, ParameterSetName = 'Name')]
		[string[]]$Name,
		[Parameter(ValueFromPipeline=$true, ParameterSetName='Obj')]
		$vDisk
	)

	begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	
	process {
		if ($Name)
		{
			$cmd = "lsvdiskhostmap -delim , "
			foreach ($Disk in $Name)
			{
				$cmd += " $Disk"
				Write-Verbose "Name is $($Disk)"
				Write-Verbose "Command is $($cmd)"
				$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
				Write-Verbose "$($info)"
				$status = ConvertFrom-Csv $info
				$status
			}
		}
		if ($Id)
		{
			$cmd = "lsvdiskhostmap -delim , "
			foreach ($Disk in $Id)
			{
				$cmd += " $Disk"
				Write-Verbose "ID is $($Disk)"
				Write-Verbose "Command is $($cmd)"
				$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
				Write-Verbose "$($info)"
				$status = ConvertFrom-Csv $info
				$status
			}
		}
		
		if ($vDisk)
		{
			$cmd = "lsvdiskhostmap -delim , $($_.Id)"
			Write-Verbose "Command is $($cmd)"
			Write-Verbose "Obj ID is $($_.Id)"
			$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
			Write-Verbose "$($info)"
			$status = ConvertFrom-Csv $info
			$status
		}
		
	}
	end {

  }
} 

function Add-V7KvDiskHostMap {
  <#
  	.SYNOPSIS
		Gets the connect Hosts to a IBM V7000
	
	.DESCRIPTION
		Gets the connected hosts to a IBM V7000
	
	.EXAMPLE
		Get-V7000System -HostName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$Hostid,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [int[]]$Id
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	
	process {
    $info = Invoke-SSHCommand -SessionId $sessionid -Command "mkvdiskhostmap -host $Hostid $Id"
    
    write-verbose "$($info)"

  }
}  

function Remove-V7KvDiskHostMap {
  <#
  	.SYNOPSIS
		Gets the connect Hosts to a IBM V7000
	
	.DESCRIPTION
		Gets the connected hosts to a IBM V7000
	
	.EXAMPLE
		Get-V7000System -HostName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High',DefaultParameterSetName="Obj")]
  param
  (
    [Parameter()]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
	[Parameter(Mandatory = $True, ParameterSetName = 'Name')]
	[Parameter(ParameterSetName = 'ID')]
    [string]$Hostid,
    [Parameter(ParameterSetName='ID')]
    [int[]]$Id,
    [Parameter(ParameterSetName='Name')]
	[string[]]$Name,
	[Parameter(ValueFromPipeline = $True, ParameterSetName = 'Obj')]
	[PSCustomObject]$HostMap

  )

	begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	
	process {
		
		if ($Name)
		{
			$cmd = "rmvdiskhostmap -host $Hostid"
			foreach ($HM in $Name)
			{
				$cmd += " $HM"
				$Msg = $HM
				Write-Verbose "Name is $($HM)"
				Write-Verbose "Command is $($cmd)"
				if ($pscmdlet.ShouldProcess($Msg))
				{
					$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
					Write-Verbose "$($info)"
				}
			}
		}
		if ($Id)
		{
			$cmd = "rmvdiskhostmap -host $Hostid"
			foreach ($HM in $Id)
			{
				$cmd += " $HM"
				$Msg = $HM
				Write-Verbose "ID is $($HM)"
				Write-Verbose "Command is $($cmd)"
				if ($pscmdlet.ShouldProcess($Msg))
				{
					$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
					Write-Verbose "$($info)"
				}
			}
		}
		if ($HostMap)
		{
			$cmd = "rmvdiskhostmap -host $($_.host_id)"
			$cmd += " $($_.Id)"
			$Msg = "$($_.Id) on $($_.host_id)"
			Write-Verbose "Object ID is $($_.Id)"
			Write-Verbose "Command is $($cmd)"
			if ($pscmdlet.ShouldProcess($Msg))
			{
				$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
				Write-Verbose "$($info)"
			}
		}
	}
}

function Get-V7KEventLog {
 <#
  	.SYNOPSIS
		Gets the event log from an IBM V7000 Storewise
	
	.DESCRIPTION
		Gets the event log from an IBM V7000 Storewise.
        NOTE: This will not work on a V7000 Unified server
	
	.EXAMPLE
		Get-V7000EventLog -ComputerName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter()]
    [ValidateSet('yes','no',IgnoreCase = $False)]
    [string]$Alert = "yes",
    [Parameter()]
    [ValidateSet('yes','no',IgnoreCase = $False)]
    [string]$Message = "yes",
    [Parameter()]
    [ValidateSet('yes','no',IgnoreCase = $False)]
    [string]$Monitoring = "no",
    [Parameter()]
    [ValidateSet('yes','no',IgnoreCase = $False)]
    [string]$Expired = "no",
    [Parameter()]
    [ValidateSet('yes','no',IgnoreCase = $False)]
    [string]$Fixed = "no",
    [Parameter()]
    [ValidateSet('date','severity',IgnoreCase = $False)]
    [string]$Order = "date"
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$defaultProperties = @('last_timestamp',‘object_name’,'status','description')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

    $cmd = "svcinfo lseventlog -delim , -alert $Alert -message $Message -monitoring $Monitoring -expired $Expired -fixed $Fixed -order $Order"
     
  }

  process {
    Write-Verbose "$($cmd)"
    $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
    $status = ConvertFrom-Csv $info
    $status | ForEach-Object {
        $_.last_timestamp -match "(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})" | Out-Null
        $_.last_timestamp = Get-Date "$($Matches[3])/$($Matches[2])/$($Matches[1]) $($Matches[4]):$($Matches[5]):$($Matches[6])"
        }
   
  }
  end {
    $status | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    return $status
  }
} 

function Get-V7KSoftwareUpgradeStatus {
 <#
  	.SYNOPSIS
		Gets the event log from an IBM V7000 Storewise
	
	.DESCRIPTION
		Gets the event log from an IBM V7000 Storewise.
        NOTE: This will not work on a V7000 Unified server
	
	.EXAMPLE
		Get-V7000EventLog -ComputerName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$True)]
        [Alias('host')]
        [string]$ComputerName = $Global:DefaultV7K.Host
    
    )

    begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$defaultProperties = @('Type',‘Name’,'CurrentState','CurrentTask','PercentComplete')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $cmd = "lssoftwareupgradestatus -nohdr"
     
    }

    process {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
    
    }
    end {
        return $info
    }
} 

function Get-V7KPartnership {
     <#
  	.SYNOPSIS
		Gets the Partnership of a IBM V7000
	
	.DESCRIPTION
		Gets the system information for an IBM V7000, this includes capacity info
        code level and ip address
        Due to the way information is returned when querying a single vdisk, the NoteProperty
        for the copy is preapended with a c. i.e status becomes cstatus
	
	.EXAMPLE
		Get-V7KPartnership
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	
	process {

    $info = (Invoke-SSHCommand -SessionId $sessionid -Command "lspartnership -delim ,").Output
    $Item = ConvertFrom-Csv $info

  }

  end {
    
    return $Item
  }
}

function New-V7KFCMap {
   [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True)]
    [string]$Source,
    [Parameter(Mandatory=$True)]
    [string]$Target,
    [Parameter()]
    [string]$Name,
    [Parameter()]
    [string]$Consistgrp,
    [Parameter()]
    [ValidateRange(0,100)]
    [int]$Copyrate,
    [Parameter()]
    [switch]$Autodelete,
    [Parameter()]
    [ValidateSet('64','256')]
    [int]$GrainSize = 256,
    [Parameter()]
    [switch]$Incremental,
    [Parameter()]
    [ValidateRange(0,100)]
    [int]$Cleanrate,
    [Parameter()]
    [int]$IOGrp
        
  ) 
   begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "mkfcmap -cleanrate $Cleanrate -copyrate $Copyrate"
    if ($Name) {$cmd += " -name $Name"}
    if ($Consistgrp) {$cmd += " -consistgrp $Consistgrp"}
    if ($Copyrate) {$cmd += " -copyrate $Copyrate"}
    if ($Autodelete) {$cmd += " -autodelete"}
    if ($GrainSize) {$cmd += " -grainsize $GrainSize"}
    if ($Incremental)  {$cmd += " -incremental"}
    if ($Cleanrate) {$cmd += " -cleanrate $Cleanrate"}  #needs error checking
    if ($IOGrp) {$cmd += " -iogrp $IOGrp"}  #needs error checking
    
    $cmd += " -source $Source -target $Target"
    
    Write-Verbose $($cmd)
    
  }

  process {
    try {
        $ErrorActionPreference = "Stop"
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $info
    }
    catch [System.Exception]{
        
        Write-Error $($_.Exception.Message)
        $ErrorActionPreference = "Continue"
    }
    

  }
}

function Remove-V7KFCMap {
  [CmdletBinding()]
  param
  (
		[Parameter()]
		[Alias('host')]
		[string]$ComputerName = $Global:DefaultV7K.Host,
		[Parameter()]
		[Parameter(ValueFromPipelineByPropertyName = $True, ParameterSetName = "ID")]
		[string[]]$Id,
		[switch]$Force,
		[Parameter(ValueFromPipeline = $True, ParameterSetName = "FCMapObj")]
		[System.Management.Automation.PSCustomObject]$FCMap
  )
  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	process {
		if ($FCMap)
		{
			$cmd = "rmfcmap"
			if ($Force) { $cmd += " -force" }
			$cmd += " $_.Id"
			Write-Verbose "FCMap ID is $($_.Id)"
			Write-Verbose "Command is $($cmd)"
		}
		if ($Id)
		{
			foreach ($item in $id)
			{
				$cmd = "rmfcmap"
				if ($Force) { $cmd += " -force" }
				$cmd += " $Item"
				Write-Verbose "ID is $($Item)"
				Write-Verbose "Command is $($cmd)"
			}
		}
		$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
		Write-Verbose "$($info)"
  }

  end {
    
  }
}

function Get-V7KFCMap {
  <#
  	.SYNOPSIS
		Gets the VDisks of a IBM V7000
	
	.DESCRIPTION
		Gets the system information for an IBM V7000, this includes capacity info
        code level and ip address
        Due to the way information is returned when querying a single vdisk, the NoteProperty
        for the copy is preapended with a c. i.e status becomes cstatus
	
	.EXAMPLE
		Get-V7000System -HostName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Position=1)]
    [string]$Id,
    [string]$SourceVolumeName
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "lsfcmap -delim ,"
    if ($Bytes) {$cmd += " -bytes"}
    if ($Id) {$cmd += " $Id"}
    if ($SourceVolumeName) {$cmd += " -filtervalue source_vdisk_name=$SourceVolumeName"}
    Write-verbose "Command : $($cmd)"
  }

  process {
    if ($Id) {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        Write-Verbose "Result : $($info)"
        $item = New-Object PSObject
        $lines = $info -split "\s+"
        foreach ($line in $lines)
        {
            $split = $line.Split(",")                
            $header = $Split[0]
            if ($Split[0]) {
                if ($Split[1] -eq $null) {
                    $Split[1] = ""
                }
                if (($Item | Get-Member).Name -eq $Split[0]) {
                    $item | Add-Member NoteProperty "c$header" $Split[1]
                }
                else {
                    $item | Add-Member NoteProperty "$header" $Split[1]
                }
            }
            
        }
     }
    else 
    {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $Item = ConvertFrom-Csv $info
    }
		
    
  }

  end {
    	return $item
  }
}

function Start-V7KFCMap {
  <#
  	.SYNOPSIS
		Start replication on a IBM V7000
	
	.DESCRIPTION
		Start replication on a IBM V7000
	
	.EXAMPLE
		Get-V7000ReplicationStatus -ComputerName 172.0.0.10 | Start-V7000Replication
	
	.EXAMPLE
		Get-V7000ReplicationStatus -ComputerName 172.0.0.10 | where-object {$_.State -ne 'consistent_synchronized'} | Start-V7000Replication

    .EXAMPLE
		$relationship = Get-V7000ReplicationStatus -ComputerName 172.0.0.10 | where-object {$_.State -ne 'consistent_synchronized'}
        Start-V7000Replication -Relationship $relationship

    .EXAMPLE
		$relationship = Get-V7000ReplicationStatus -ComputerName 172.0.0.10 | where-object {$_.State -ne 'consistent_synchronized'}
        $relationship | Start-V7000Replication
	  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding()]
  param
  (
    [string]$Id
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	
	process {
        $cmd = "startfcmap -prep $Id"
        Write-Verbose "Starting $($_.Name)"
        $info = (Invoke-SSHCommand -SessionId $SessionId -Command $cmd).Output
        $info
   
  }
}

function Stop-V7KFCMap {
  [CmdletBinding(DefaultParameterSetName="FCMapObj")]
  param
  (
    [Parameter()]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter()]
	[Parameter(ValueFromPipelineByPropertyName = $True, ParameterSetName = "ID")]
	[string[]]$Id,
	[switch]$Force,
	[Parameter(ValueFromPipeline = $True, ParameterSetName="FCMapObj")]
	[System.Management.Automation.PSCustomObject]$FCMap
  )
  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		
	}
	process
	{
		if ($FCMap)
		{
			$cmd = "stopfcmap"
			if ($Force) { $cmd += " -force" }
			$cmd += " $_.Id"
			Write-Verbose "FCMap ID is $($_.Id)"
			Write-Verbose "Command is $($cmd)"
		}
		if ($Id)
		{
			foreach ($item in $id)
			{
				$cmd = "stopfcmap"
				if ($Force) { $cmd += " -force" }
				$cmd += " $Item"
				Write-Verbose "ID is $($Item)"
				Write-Verbose "Command is $($cmd)"
			}
		}
		$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
		Write-Verbose "$($info)"
	}

	end {

	}
}

function Get-V7000VDiskDependantMaps {
  <#
  	.SYNOPSIS
		 Displays all FlashCopy mappings with target volumes that are dependent upon data held on the specified volume. 
	
	.DESCRIPTION
		The lsvdiskdependentmaps command displays FlashCopy mappings that have target volumes that are dependent upon data 
        held on the specified vdisk. This can be used to determine whether a FlashCopy mapping can be prepared. Issue the 
        command for the target volume vdisk of the FlashCopy mapping to be prepared. If no FlashCopy mappings are returned, 
        the FlashCopy mapping can be prepared. Any FlashCopy mappings that are returned in the list must be stopped or be in 
        the idle_or_copied state, before the new FlashCopy mapping can be prepared.

	
	.EXAMPLE
		Get-V7000VDiskDependantMaps -ComputerName 172.0.0.10 -Id 2
	
	.EXAMPLE
		Get-V7000VDiskDependantMaps -ComputerName 172.0.0.10 -Name Vdisk1
	  
	.PARAMETER ComputerName
		IP address or DNS name of the V7000

    .PARAMETER Id
        Id of an Object

    .PARAMETER Name
        Name of an Object
	
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName)]
    [Alias('host')]
    [string]$ComputerName,
    [Parameter(Mandatory=$True,ParameterSetName='ID')]
    [int]$Id,
    [Parameter(Mandatory=$True,ParameterSetName='Name')]
    [string]$Name
  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "lsvdiskdependentmaps -delim ,"
    if ($ID) {$cmd += " $Id"}
    if ($Name) {$cmd += " $Name"}
    
    Write-Verbose "$($cmd)"   
  }

  process {
    $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
    $status = ConvertFrom-Csv $info

  }
  end {
    return $status
  }
}

function Get-V7KDrive {
  <#
  	.SYNOPSIS
		Gets the Drives of a IBM V7000
	
	.DESCRIPTION
		Gets the system information for an IBM V7000, this includes capacity info
        code level and ip address
        Due to the way information is returned when querying a single vdisk, the NoteProperty
        for the copy is preapended with a c. i.e status becomes cstatus
	
	.EXAMPLE
		Get-V7000System -HostName 172.0.0.10
	
	.EXAMPLE
		Give another example of how to use it
	  
	.PARAMETER HostName
		IP address or DNS name of the V7000
	
  #>
  [CmdletBinding(DefaultParameterSetName="All")]
  param
  (
    [Parameter(ValueFromPipeline=$True)]
    [Alias('host')]
    [string]$ComputerName = $Global:DefaultV7K.Host,
    [Parameter(Mandatory=$True,ParameterSetName='ID')]
    [int]$Id,
    [Parameter(Mandatory=$True,ParameterSetName='Name')]
    [string]$Name

  )

  begin {
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "lsdrive -delim ,"
    if ($Bytes) {$cmd += " -bytes"}
    if ($Id) {$cmd += " $Id"}
  }

  process {
    if ($Id) {
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $item = New-Object PSObject
        $lines = $info -split "\s+"
        foreach ($line in $lines)
        {
            $split = $line.Split(",")                
            $header = $Split[0]
            if ($Split[0]) {
                if ($Split[1] -eq $null) {
                    $Split[1] = ""
                }
                if (($Item | Get-Member).Name -eq $Split[0]) {
                    $item | Add-Member NoteProperty "c$header" $Split[1]
                }
                else {
                    $item | Add-Member NoteProperty "$header" $Split[1]
                }
            }
            
        }
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
     }
    else {
        $defaultProperties = @('Id',‘Status’,'capacity','mdisk_name')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
        $info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
        $Item = ConvertFrom-Csv $info
        $item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
        $Item | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    }
    
  }

  end {
    
    return $Item
  }
}

Function New-V7KBackupSnapshot {
    <#
  	.SYNOPSIS
		Creates a snapshot for a EMC NetWorker backup
	
	.DESCRIPTION
		This function creates a thin provisioned snapshot on a V7000 of a volume and presents it to
        a host for backup.

	.PARAMETER V7000Host
		The dns name of the V7000
	
    .PARAMETER V7KUserName
		The Username of the account connecting to the V7000
	
	.PARAMETER V7KPassword
		The password of the account connecting to the V7000
	
	.PARAMETER KeyFile
		The SSH public  key of the account.  Must be in OpenSSH format
	
	.PARAMETER SourceVolume
		The name of the Source volume to be snapshot.
	
	.PARAMETER TargetVolume
		The name of the snapshot volume.  The current date and time will be appended to the end of the volume name
	
	.PARAMETER TargetHostId
		The ID of the host defined on the V7000 that the snapshot will be mounted on
	
	.PARAMETER Pool
		The name of the pool (Mdisk Group) for the snapshot volume to be created on
	
	.PARAMETER RetryTime
		The number of seconds in between retries.  Default is 10 seconds
	
	.PARAMETER Retries
		The Number of retries to attemp.  Default is 6
	
	.PARAMETER LogFile
        The name of the Log file to output infomation to be written to for troubleshooting.
		The default location is the NetWorker logs directory and will be called V7KSnapshot.log.
		If this does not exist it will be put in %systemroot%\temp
	
	.EXAMPLE
		New-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -SourceVolume Vol1 -TargetVolume Vol1_BU -Pool Pool1 
	        -TargetHostId 2 -KeyFile C:\temp\key.ppk
	.EXAMPLE
		New-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -SourceVolume Vol1 -TargetVolume Vol1_BU -Pool Pool1 
	        -TargetHostId 2 -KeyFile C:\temp\key.ppk -Verbose
	  
	.OUTPUTS
		This will output a CSV file int %systemroot\temp called the name of the source volume.  This is used to remove the snapshot using the
		Remove-V7KBackupSnapshot Cmdlet
	
	.NOTES
        Before using the disk, make sure you have manually created a snapshot and mounted it to the desired host.
        The drive letter that gets assigned to it is the one you need to define in the networker client.
	
  #>
    [CmdletBinding()]
    Param (
        [string]$LogFile,
        [Parameter(Mandatory=$True)]
        [string]$KeyFile,
        [Parameter(Mandatory=$True)]
        [string]$V7KUserName,
        [Parameter(Mandatory=$True)]
        [string]$V7000Host,
        [Parameter(Mandatory=$True)]
        [string]$SourceVolume,
        [Parameter(Mandatory=$True)]
        [string]$TargetVolume,
        [Parameter()]
        [string]$TargetHostID,
        [Parameter(Mandatory=$True)]
		[string]$Pool,
		[string]$CSVFile = "$env:SystemRoot\Temp\$SourceVolume.csv",
        [int]$RetryTime = 10,
        [int]$Retries = 6

         
    )
    if (-not $LogFile)
    {
		$Logfile = (Get-ItemProperty HKLM:\SOFTWARE\Legato\NetWorker).Path + "logs\V7KSnapshot.log"
		$Exist = Test-Path $LogFile
		If (-not $Exist)
		{
			$LogFile = "$env:SystemRoot\Temp\V7KSnapshot.log"	
		}
	}
	Write-Verbose "Log file is $($LogFile)"
    Write-Verbose "Key File is $($KeyFile)"
    Write-Verbose "Host is $($V7000Host)"
    Write-Verbose "Username is $($V7KUserName)"
    Write-Verbose "Source volume is $($SourceVolume)"
    Write-Verbose "Target host is $($TargetHostID)"
    Write-Verbose "Target pool is $($Pool)"
	$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $V7KUserName, (new-object System.Security.SecureString)
    Get-Date | out-File $LogFile
    $Date = Get-Date -UFormat %d%m%y%H%M%S
    $Date | Out-File $LogFile -Append
    $TargetVolumeName = "$TargetVolume`_$date"
    "TargetVolume: $TargetVolumeName" | Out-File $logfile -Append
    Write-Verbose "Target volume is $($TargetVolumeName)"
    "V7000 Host: $V7000Host" | Out-File $LogFile -Append
    $DiskSurfaced = 1

    #Connects to the V7000, creates the target disk and creates the snapshot 
    Write-Verbose "Connecting to $($V7000Host)" 
    "Connecting to V7000 ($V7000Host)" | Out-File $logfile -Append
    Connect-V7K -Computername $V7000Host -Credential $cred -KeyFile $KeyFile
    Get-SSHSession | Out-File $logfile -Append
    
    $SoureVolumeInfo = Get-V7KVDisk -Name $SourceVolume -Bytes
    "Source Volume info: $SourceVolumeInfo" | Out-File $logfile -Append
    $TargetSize = $SoureVolumeInfo.Capacity
    "Target size: $TargetSize" | Out-File $logfile -Append
    Write-Verbose "Target volume capacity is $($TargetSize)"
    Write-Verbose "Creating target volume $($TargetVolumeName)"
    
    "Creating $TargetVolumeName on $Pool" | Out-File $logfile -Append
    New-V7KVDisk -Mdiskgrp $Pool -Name $TargetVolumeName -Size $TargetSize -Unit b
    "Source volume info: $SoureVolumeInfo" | Select-Object ID,Name,Capacity | Out-File $LogFile -Append
    
    Write-Verbose "Creating snapshot"
    $FlashCopyResult = New-V7KFCMap -Cleanrate 0 -Copyrate 0 -Source $SourceVolume -Target $TargetVolumeName
    Write-Verbose "$($FlashCopyResult)"
    "Flash Copy result: $FlashCopyResult" | Out-File $LogFile -Append
    $FlashCopyResult -match "\[(\d+)\]" | Out-Null
    $FlashCopyId = $Matches[1]
    Write-Verbose "Flash copy Id is $($FlashCopyId)"
    "Flash copy ID:$FlashCopyId" | Out-File $LogFile -Append
    Write-Verbose "Starting flash copy $($FlashCopyId)"
    "Startinf FCMap" | Out-File $logfile -Append
    Start-V7KFCMap -Id $FlashCopyId

    #Maps the snapshot to a host
    if ($TargetHostID)
    {
        $SnapVolumeId = (Get-V7KVDisk -Name $TargetVolumeName).id
        Write-Verbose "Snapshot volume ID is $($SnapVolumeId)"
        "Snap volume id:$SnapVolumeId" | Out-File $LogFile -Append
        Write-Verbose "Adding volume $($SnapVolumeId) to host $($TargetHostID)"
        "Adding volume $SnapVolumeId to host $TargetHostID" | Out-File $LogFile -Append
	    Add-V7KvDiskHostMap -Hostid $TargetHostID -Id $SnapVolumeID
        Write-Verbose "Waiting for 30 seconds for disk to surface on host"
        "Waiting for 30 seconds for disk to surface on host" | Out-File $LogFile -Append
        Start-Sleep -Seconds 30
        Write-Verbose "Rescaning disk on host"
        "Scanning host for new disk" | Out-File $LogFile -Append
        Update-HostStorageCache

        #Detects the disk and mounts it
        Write-Verbose "Finding the disk"
        $disk = Get-Disk | where-object {$_.OperationalStatus -eq 'Offline'}
        "Disk: $disk" | Out-File $LogFile -Append
        Write-Verbose "Found disk $($disk)"
        Write-Verbose "Marking disk as read/write"
        $disk | Set-Disk -IsOffline:$false
        Write-Verbose "Changing disk to Online"
        $disk | Set-Disk -IsReadOnly:$false
        $Volume = $disk | Get-Partition
        Write-Verbose "Mounted volume has been assign $($Volume.DriveLetter)" | Out-File $LogFile -Append
        "Mounted volume has been assign $($Volume.DriveLetter)"
        $hash = [ordered]@{
            V7000Host = $V7000Host
            SourceVolume = $SourceVolume
            TargetVolume = $TargetVolumeName
            TargetHostID = $TargetHostID
            SnapVolumeId = $SnapVolumeId
            FlashCopyId = $FlashCopyId
            OSDiskID = $disk.Number
	    }
	    Write-Verbose "Exporting CSV to $($CSVFile)"
        "CSV file is located at $CSVFile" | Out-File $LogFile -Append
	    New-Object -TypeName PSObject -Property $hash | Export-CSV -Path $CSVFile
	    Write-Verbose "Disconnecting from $($V7000Host)"
    }
    Get-SSHSession | Remove-SSHSession
}

Function Get-V7KSnapshot {
    <#
  	.SYNOPSIS
		Creates a snapshot for a EMC NetWorker backup
	
	.DESCRIPTION
		This function creates a thin provisioned snapshot on a V7000 of a volume and presents it to
        a host for backup.

	.PARAMETER V7000Host
		The dns name of the V7000
	
    .PARAMETER V7KUserName
		The Username of the account connecting to the V7000
	
	.PARAMETER V7KPassword
		The password of the account connecting to the V7000
	
	.PARAMETER KeyFile
		The SSH public  key of the account.  Must be in OpenSSH format
	
	.PARAMETER SourceVolume
		The name of the Source volume to be snapshot.
	
	.PARAMETER TargetVolume
		The name of the snapshot volume.  The current date and time will be appended to the end of the volume name
	
	.PARAMETER TargetHostId
		The ID of the host defined on the V7000 that the snapshot will be mounted on
	
	.PARAMETER Pool
		The name of the pool (Mdisk Group) for the snapshot volume to be created on
	
	.PARAMETER RetryTime
		The number of seconds in between retries.  Default is 10 seconds
	
	.PARAMETER Retries
		The Number of retries to attemp.  Default is 6
	
	.PARAMETER LogFile
        The name of the Log file to output infomation to be written to for troubleshooting.
		The default location is the NetWorker logs directory and will be called V7KSnapshot.log.
		If this does not exist it will be put in %systemroot%\temp
	
	.EXAMPLE
		New-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -SourceVolume Vol1 -TargetVolume Vol1_BU -Pool Pool1 
	        -TargetHostId 2 -KeyFile C:\temp\key.ppk
	.EXAMPLE
		New-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -SourceVolume Vol1 -TargetVolume Vol1_BU -Pool Pool1 
	        -TargetHostId 2 -KeyFile C:\temp\key.ppk -Verbose
	  
	.OUTPUTS
		This will output a CSV file int %systemroot\temp called the name of the source volume.  This is used to remove the snapshot using the
		Remove-V7KBackupSnapshot Cmdlet
	
	.NOTES
        Before using the disk, make sure you have manually created a snapshot and mounted it to the desired host.
        The drive letter that gets assigned to it is the one you need to define in the networker client.
	
  #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$KeyFile,
        [Parameter(Mandatory=$True)]
        [string]$V7KUserName,
        [Parameter(Mandatory=$True)]
        [string]$V7000Host,
        [Parameter(Mandatory=$True)]
        [string]$SourceVolume

         
    )
    Write-Verbose "Key File is $($KeyFile)"
    Write-Verbose "Host is $($V7000Host)"
    Write-Verbose "Username is $($V7KUserName)"
    Write-Verbose "Source volume is $($SourceVolume)"
    Write-Verbose "Target host is $($TargetHostID)"
    Write-Verbose "Target pool is $($Pool)"
	$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $V7KUserName, (new-object System.Security.SecureString)


    #Connects to the V7000, creates the target disk and creates the snapshot 
    Write-Verbose "Connecting to $($V7000Host)" 
    "Connecting to V7000 ($V7000Host)" | Out-File $logfile -Append
    Connect-V7K -Computername $V7000Host -Credential $cred -KeyFile $KeyFile
    
    $FCInfo = Get-V7KFCMap -SourceVolumeName $SourceVolume
    $TargetVolInfo = Get-V7KVDisk -id $FCInfo.target_vdisk_id
    $MappingInfo = Get-V7KVDiskHostMap -id $TargetVolInfo.id
    If ($MappingInfo) {$isMapped = $True} else {$isMapped = $false}
    $SnapInfo = [ordered]@{
        SourceVolumeId = $FCInfo.source_vdisk_id
        SourceVolumeName = $FCInfo.source_vdisk_name
        TargetVolumeId = $FCInfo.target_vdisk_id
        TargetVolumeName = $FCInfo.target_vdisk_name
        isMappedToHost = $isMapped
        HostId = $MappingInfo.host_id
        FCMapId = $FCInfo.id
        FCMapName = $FCInfo.name

    }
    New-Object -TypeName PSObject -Property $SnapInfo
}

Function New-V7KSnapshot {
    <#
  	.SYNOPSIS
		Creates a snapshot for a EMC NetWorker backup
	
	.DESCRIPTION
		This function creates a thin provisioned snapshot on a V7000 of a volume and presents it to
        a host for backup.

	.PARAMETER V7000Host
		The dns name of the V7000
	
    .PARAMETER V7KUserName
		The Username of the account connecting to the V7000
	
	.PARAMETER V7KPassword
		The password of the account connecting to the V7000
	
	.PARAMETER KeyFile
		The SSH public  key of the account.  Must be in OpenSSH format
	
	.PARAMETER SourceVolume
		The name of the Source volume to be snapshot.
	
	.PARAMETER TargetVolume
		The name of the snapshot volume.  The current date and time will be appended to the end of the volume name
	
	.PARAMETER TargetHostId
		The ID of the host defined on the V7000 that the snapshot will be mounted on
	
	.PARAMETER Pool
		The name of the pool (Mdisk Group) for the snapshot volume to be created on
	
	.PARAMETER RetryTime
		The number of seconds in between retries.  Default is 10 seconds
	
	.PARAMETER Retries
		The Number of retries to attemp.  Default is 6
	
	.PARAMETER LogFile
        The name of the Log file to output infomation to be written to for troubleshooting.
		The default location is the NetWorker logs directory and will be called V7KSnapshot.log.
		If this does not exist it will be put in %systemroot%\temp
	
	.EXAMPLE
		New-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -SourceVolume Vol1 -TargetVolume Vol1_BU -Pool Pool1 
	        -TargetHostId 2 -KeyFile C:\temp\key.ppk
	.EXAMPLE
		New-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -SourceVolume Vol1 -TargetVolume Vol1_BU -Pool Pool1 
	        -TargetHostId 2 -KeyFile C:\temp\key.ppk -Verbose
	  
	.OUTPUTS
		This will output a CSV file int %systemroot\temp called the name of the source volume.  This is used to remove the snapshot using the
		Remove-V7KBackupSnapshot Cmdlet
	
	.NOTES
        Before using the disk, make sure you have manually created a snapshot and mounted it to the desired host.
        The drive letter that gets assigned to it is the one you need to define in the networker client.
	
  #>
    [CmdletBinding()]
    Param (
        [string]$LogFile,
        [Parameter(Mandatory=$True)]
        [string]$KeyFile,
        [Parameter(Mandatory=$True)]
        [string]$V7KUserName,
        [Parameter(Mandatory=$True)]
        [string]$V7000Host,
        [Parameter(Mandatory=$True)]
        [string]$SourceVolume,
        [Parameter(Mandatory=$True)]
        [string]$TargetVolume,
        [Parameter()]
        [string]$TargetHostID,
        [Parameter(Mandatory=$True)]
		[string]$Pool,
		[string]$CSVFile = "$env:SystemRoot\Temp\$SourceVolume.csv",
        [int]$RetryTime = 10,
        [int]$Retries = 6

         
    )
    if (-not $LogFile)
    {
		$Logfile = (Get-ItemProperty HKLM:\SOFTWARE\Legato\NetWorker).Path + "logs\V7KSnapshot.log"
		$Exist = Test-Path $LogFile
		If (-not $Exist)
		{
			$LogFile = "$env:SystemRoot\Temp\V7KSnapshot.log"	
		}
	}
	Write-Verbose "Log file is $($LogFile)"
    Write-Verbose "Key File is $($KeyFile)"
    Write-Verbose "Host is $($V7000Host)"
    Write-Verbose "Username is $($V7KUserName)"
    Write-Verbose "Source volume is $($SourceVolume)"
    Write-Verbose "Target host is $($TargetHostID)"
    Write-Verbose "Target pool is $($Pool)"
	$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $V7KUserName, (new-object System.Security.SecureString)
    Get-Date | out-File $LogFile
    $Date = Get-Date -UFormat %d%m%y%H%M%S
    $Date | Out-File $LogFile -Append
    $TargetVolumeName = "$TargetVolume`_$date"
    "TargetVolume: $TargetVolumeName" | Out-File $logfile -Append
    Write-Verbose "Target volume is $($TargetVolumeName)"
    "V7000 Host: $V7000Host" | Out-File $LogFile -Append
    $DiskSurfaced = 1

    #Connects to the V7000, creates the target disk and creates the snapshot 
    Write-Verbose "Connecting to $($V7000Host)" 
    "Connecting to V7000 ($V7000Host)" | Out-File $logfile -Append
    Connect-V7K -Computername $V7000Host -Credential $cred -KeyFile $KeyFile
    Get-SSHSession | Out-File $logfile -Append
    
    $SoureVolumeInfo = Get-V7KVDisk -Name $SourceVolume -Bytes
    "Source Volume info: $SourceVolumeInfo" | Out-File $logfile -Append
    $TargetSize = $SoureVolumeInfo.Capacity
    "Target size: $TargetSize" | Out-File $logfile -Append
    Write-Verbose "Target volume capacity is $($TargetSize)"
    Write-Verbose "Creating target volume $($TargetVolumeName)"
    
    "Creating $TargetVolumeName on $Pool" | Out-File $logfile -Append
    New-V7KVDisk -Mdiskgrp $Pool -Name $TargetVolumeName -Size $TargetSize -Unit b
    "Source volume info: $SoureVolumeInfo" | Select-Object ID,Name,Capacity | Out-File $LogFile -Append
    
    Write-Verbose "Creating snapshot"
    $FlashCopyResult = New-V7KFCMap -Cleanrate 0 -Copyrate 0 -Source $SourceVolume -Target $TargetVolumeName
    Write-Verbose "$($FlashCopyResult)"
    "Flash Copy result: $FlashCopyResult" | Out-File $LogFile -Append
    $FlashCopyResult -match "\[(\d+)\]" | Out-Null
    $FlashCopyId = $Matches[1]
    Write-Verbose "Flash copy Id is $($FlashCopyId)"
    "Flash copy ID:$FlashCopyId" | Out-File $LogFile -Append
    Write-Verbose "Starting flash copy $($FlashCopyId)"
    "Startinf FCMap" | Out-File $logfile -Append
    Start-V7KFCMap -Id $FlashCopyId

    #Maps the snapshot to a host
    if ($TargetHostID)
    {
        $SnapVolumeId = (Get-V7KVDisk -Name $TargetVolumeName).id
        Write-Verbose "Snapshot volume ID is $($SnapVolumeId)"
        "Snap volume id:$SnapVolumeId" | Out-File $LogFile -Append
        Write-Verbose "Adding volume $($SnapVolumeId) to host $($TargetHostID)"
        "Adding volume $SnapVolumeId to host $TargetHostID" | Out-File $LogFile -Append
	    Add-V7KvDiskHostMap -Hostid $TargetHostID -Id $SnapVolumeID
        
        
    }
    $hash = [ordered]@{
            V7000Host = $V7000Host
            SourceVolume = $SourceVolume
            TargetVolume = $TargetVolumeName
            SnapVolumeId = $SnapVolumeId
            FlashCopyId = $FlashCopyId
	}
    if ($TargetHostID)
    {
        $hash.Add('TargetHostID', $TargetHostID)
    }
	Write-Verbose "Exporting CSV to $($CSVFile)"
    "CSV file is located at $CSVFile" | Out-File $LogFile -Append
	New-Object -TypeName PSObject -Property $hash | Export-CSV -Path $CSVFile
	Write-Verbose "Disconnecting from $($V7000Host)"
    Get-SSHSession | Remove-SSHSession
}

Function Remove-V7KSnapshot {
    <#
  	.SYNOPSIS
		Creates a snapshot for a EMC NetWorker backup
	
	.DESCRIPTION
		This function creates a thin provisioned snapshot on a V7000 of a volume and presents it to
        a host for backup.

	.PARAMETER V7000Host
		The dns name of the V7000
	
    .PARAMETER V7KUserName
		The Username of the account connecting to the V7000
	
	.PARAMETER V7KPassword
		The password of the account connecting to the V7000
	
	.PARAMETER KeyFile
		The SSH public  key of the account.  Must be in OpenSSH format
	
	.PARAMETER RetryTime
		The number of seconds in between retries.  Default is 10 seconds
	
	.PARAMETER Retries
		The Number of retries to attemp.  Default is 6
	
	.PARAMETER LogFile
        The name of the Log file to output infomation to be written to for troubleshooting.
		The default location is the NetWorker logs directory and will be called V7KSnapshot.log.
		If this does not exist it will be put in %systemroot%\temp
        
	.EXAMPLE
		Remove-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -KeyFile C:\temp\key.ppk
			-Path C:\Windows\Temp\Vol.csv
	.NOTES
        The Keyfile has to be in OpenSSH format

	
  #>
    [CmdletBinding()]
    Param (
        [string]$LogFile,
        [Parameter()]
        [string]$KeyFile,
        [Parameter(Mandatory=$True)]
        [string]$V7KUserName,

		[string]$Path,
		[int]$RetryCount = 30,
		[int]$RetryDelay = 5

         
    )
    if (-not $LogFile)
    {
        $Logfile = (Get-ItemProperty HKLM:\SOFTWARE\Legato\NetWorker).Path + "logs\V7KSnapshot.log"
    }
    $SnapInfo = Import-Csv -Path $Path
    Write-Verbose "Log file is $($LogFile)"
    Write-Verbose "Key File is $($KeyFile)"
    Write-Verbose "Host is $($SnapInfo.V7000Host)"
    Write-Verbose "Username is $($V7KUserName)"
    Write-Verbose "Source volume is $($SnapInfo.SourceVolume)"
    Write-Verbose "Target host is $($SnapInfo.TargetHostID)"
    Write-Verbose "Target volume is $($SnapInfo.TargetVolume)"
	$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $V7KUserName, (new-object System.Security.SecureString)
	$V7000Host | Out-File $LogFile -Append

    #Connects to the V7000, creates the target disk and creates the snapshot 
    Write-Verbose "Connecting to $($SnapInfo.V7000Host)" 
    Connect-V7K -Computername $SnapInfo.V7000Host -Credential $Cred -KeyFile $KeyFile
    Write-Verbose "Removing host mapping $($SnapInfo.TargetVolume) from hostid $($SnapInfo.TargetHostID)"
	if ($SnapInfo.TargetVolume)
    {
        Remove-V7KvDiskHostMap -Hostid $SnapInfo.TargetHostID -Name $SnapInfo.TargetVolume -Confirm:$false
    }
    Write-Verbose "Stopping Flash copy $($SnapInfo.FlashCopyId)"
	Stop-V7KFCMap -Id $SnapInfo.FlashCopyId
	Write-Verbose "Getting flash copy state"
	$isStopped = Get-V7KFCMap -id $SnapInfo.FlashCopyId
	Write-Verbose "Flash copy state is $($isStopped.Status)"
	while ($isStopped.Status -ne 'Stopped' -and $RetryCount -ne 0)
	{
		Write-Verbose "Flash copy is not stopped. Waiting for $($RetryDelay) seconds. Retry count:$($RetryCount)"
		Start-Sleep -Seconds $RetryDelay
		$RetryCount -= 1
		$isStopped = Get-V7KFCMap -id $SnapInfo.FlashCopyId
	}
	If ($isStopped.Status -eq 'Stopped')
	{
		Write-Verbose "Deleting flash copy $($SnapInfo.FlashCopyId)"
		Remove-V7KFCMap -Id $SnapInfo.FlashCopyId -Force
		Write-Verbose "Removing snapshot volume $($SnapInfo.TargetVolume)"
		Remove-V7KVDisk -Name $SnapInfo.TargetVolume -Confirm:$False
	}
	else
	{
		Write-Error "Flash copy could not be stopped.  Please wait for it to stop and then remove the flash copy and volume manually using 
			Remove-V7KFCmap -force -id $($SnapInfo.FlashCopyId) and then Remove-V7KVDisk -Name $($SnapInfo.TargetVolume) -Confirm:`$False"
	}
	Get-SSHSession | Remove-SSHSession
	
}

Function New-V7KBackupSnapshot {
    <#
  	.SYNOPSIS
		Creates a snapshot for a EMC NetWorker backup
	
	.DESCRIPTION
		This function creates a thin provisioned snapshot on a V7000 of a volume and presents it to
        a host for backup.

	.PARAMETER V7000Host
		The dns name of the V7000
	
    .PARAMETER V7KUserName
		The Username of the account connecting to the V7000
	
	.PARAMETER V7KPassword
		The password of the account connecting to the V7000
	
	.PARAMETER KeyFile
		The SSH public  key of the account.  Must be in OpenSSH format
	
	.PARAMETER SourceVolume
		The name of the Source volume to be snapshot.
	
	.PARAMETER TargetVolume
		The name of the snapshot volume.  The current date and time will be appended to the end of the volume name
	
	.PARAMETER TargetHostId
		The ID of the host defined on the V7000 that the snapshot will be mounted on
	
	.PARAMETER Pool
		The name of the pool (Mdisk Group) for the snapshot volume to be created on
	
	.PARAMETER RetryTime
		The number of seconds in between retries.  Default is 10 seconds
	
	.PARAMETER Retries
		The Number of retries to attemp.  Default is 6
	
	.PARAMETER LogFile
        The name of the Log file to output infomation to be written to for troubleshooting.
		The default location is the NetWorker logs directory and will be called V7KSnapshot.log.
		If this does not exist it will be put in %systemroot%\temp
	
	.EXAMPLE
		New-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -SourceVolume Vol1 -TargetVolume Vol1_BU -Pool Pool1 
	        -TargetHostId 2 -KeyFile C:\temp\key.ppk
	.EXAMPLE
		New-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -SourceVolume Vol1 -TargetVolume Vol1_BU -Pool Pool1 
	        -TargetHostId 2 -KeyFile C:\temp\key.ppk -Verbose
	  
	.OUTPUTS
		This will output a CSV file int %systemroot\temp called the name of the source volume.  This is used to remove the snapshot using the
		Remove-V7KBackupSnapshot Cmdlet
	
	.NOTES
        Before using the disk, make sure you have manually created a snapshot and mounted it to the desired host.
        The drive letter that gets assigned to it is the one you need to define in the networker client.
	
  #>
    [CmdletBinding()]
    Param (
        [string]$LogFile,
        [Parameter(Mandatory=$True)]
        [string]$KeyFile,
        [Parameter(Mandatory=$True)]
        [string]$V7KUserName,
        [Parameter(Mandatory=$True)]
        [string]$V7000Host,
        [Parameter(Mandatory=$True)]
        [string]$SourceVolume,
        [Parameter(Mandatory=$True)]
        [string]$TargetVolume,
        [Parameter()]
        [string]$TargetHostID,
        [Parameter(Mandatory=$True)]
		[string]$Pool,
		[string]$CSVFile = "$env:SystemRoot\Temp\$SourceVolume.csv",
        [int]$RetryTime = 10,
        [int]$Retries = 6

         
    )
    if (-not $LogFile)
    {
		$Logfile = (Get-ItemProperty HKLM:\SOFTWARE\Legato\NetWorker).Path + "logs\V7KSnapshot.log"
		$Exist = Test-Path $LogFile
		If (-not $Exist)
		{
			$LogFile = "$env:SystemRoot\Temp\V7KSnapshot.log"	
		}
	}
	Write-Verbose "Log file is $($LogFile)"
    Write-Verbose "Key File is $($KeyFile)"
    Write-Verbose "Host is $($V7000Host)"
    Write-Verbose "Username is $($V7KUserName)"
    Write-Verbose "Source volume is $($SourceVolume)"
    Write-Verbose "Target host is $($TargetHostID)"
    Write-Verbose "Target pool is $($Pool)"
	$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $V7KUserName, (new-object System.Security.SecureString)
    Get-Date | out-File $LogFile
    $Date = Get-Date -UFormat %d%m%y%H%M%S
    $Date | Out-File $LogFile -Append
    $TargetVolumeName = "$TargetVolume`_$date"
    "TargetVolume: $TargetVolumeName" | Out-File $logfile -Append
    Write-Verbose "Target volume is $($TargetVolumeName)"
    "V7000 Host: $V7000Host" | Out-File $LogFile -Append
    $DiskSurfaced = 1

    #Connects to the V7000, creates the target disk and creates the snapshot 
    Write-Verbose "Connecting to $($V7000Host)" 
    "Connecting to V7000 ($V7000Host)" | Out-File $logfile -Append
    Connect-V7K -Computername $V7000Host -Credential $cred -KeyFile $KeyFile
    Get-SSHSession | Out-File $logfile -Append
    
    $SoureVolumeInfo = Get-V7KVDisk -Filter name=$SourceVolume -Bytes
    "Source Volume info: $SourceVolumeInfo" | Out-File $logfile -Append
    $TargetSize = $SoureVolumeInfo.Capacity
    "Target size: $TargetSize" | Out-File $logfile -Append
    Write-Verbose "Target volume capacity is $($TargetSize)"
    Write-Verbose "Creating target volume $($TargetVolumeName)"
    
    "Creating $TargetVolumeName on $Pool" | Out-File $logfile -Append
    New-V7KVDisk -Mdiskgrp $Pool -Name $TargetVolumeName -Size $TargetSize -Unit b
    "Source volume info: $SoureVolumeInfo" | Select-Object ID,Name,Capacity | Out-File $LogFile -Append
    
    Write-Verbose "Creating snapshot"
    $FlashCopyResult = New-V7KFCMap -Cleanrate 0 -Copyrate 0 -Source $SourceVolume -Target $TargetVolumeName
    Write-Verbose "$($FlashCopyResult)"
    "Flash Copy result: $FlashCopyResult" | Out-File $LogFile -Append
    $FlashCopyResult -match "\[(\d+)\]" | Out-Null
    $FlashCopyId = $Matches[1]
    Write-Verbose "Flash copy Id is $($FlashCopyId)"
    "Flash copy ID:$FlashCopyId" | Out-File $LogFile -Append
    Write-Verbose "Starting flash copy $($FlashCopyId)"
    "Startinf FCMap" | Out-File $logfile -Append
    Start-V7KFCMap -Id $FlashCopyId

    #Maps the snapshot to a host
    if ($TargetHostID)
    {
        $SnapVolumeId = (Get-V7KVDisk -filter name=$TargetVolumeName).id
        Write-Verbose "Snapshot volume ID is $($SnapVolumeId)"
        "Snap volume id:$SnapVolumeId" | Out-File $LogFile -Append
        Write-Verbose "Adding volume $($SnapVolumeId) to host $($TargetHostID)"
        "Adding volume $SnapVolumeId to host $TargetHostID" | Out-File $LogFile -Append
	    Add-V7KvDiskHostMap -Hostid $TargetHostID -Id $SnapVolumeID
        Write-Verbose "Waiting for 30 seconds for disk to surface on host"
        "Waiting for 30 seconds for disk to surface on host" | Out-File $LogFile -Append
        Start-Sleep -Seconds 30
        Write-Verbose "Rescaning disk on host"
        "Scanning host for new disk" | Out-File $LogFile -Append
        Update-HostStorageCache

        #Detects the disk and mounts it
        Write-Verbose "Finding the disk"
        $disk = Get-Disk | where-object {$_.OperationalStatus -eq 'Offline'}
        "Disk: $disk" | Out-File $LogFile -Append
        Write-Verbose "Found disk $($disk)"
        Write-Verbose "Marking disk as read/write"
        $disk | Set-Disk -IsOffline:$false
        Write-Verbose "Changing disk to Online"
        $disk | Set-Disk -IsReadOnly:$false
        $Volume = $disk | Get-Partition
        Write-Verbose "Mounted volume has been assign $($Volume.DriveLetter)" | Out-File $LogFile -Append
        "Mounted volume has been assign $($Volume.DriveLetter)"
        $hash = [ordered]@{
            V7000Host = $V7000Host
            SourceVolume = $SourceVolume
            TargetVolume = $TargetVolumeName
            TargetHostID = $TargetHostID
            SnapVolumeId = $SnapVolumeId
            FlashCopyId = $FlashCopyId
            OSDiskID = $disk.Number
	    }
	    Write-Verbose "Exporting CSV to $($CSVFile)"
        "CSV file is located at $CSVFile" | Out-File $LogFile -Append
	    New-Object -TypeName PSObject -Property $hash | Export-CSV -Path $CSVFile
	    Write-Verbose "Disconnecting from $($V7000Host)"
    }
    Get-SSHSession | Remove-SSHSession
}

Function Remove-V7KBackupSnapshot {
    <#
  	.SYNOPSIS
		Creates a snapshot for a EMC NetWorker backup
	
	.DESCRIPTION
		This function creates a thin provisioned snapshot on a V7000 of a volume and presents it to
        a host for backup.

	.PARAMETER V7000Host
		The dns name of the V7000
	
    .PARAMETER V7KUserName
		The Username of the account connecting to the V7000
	
	.PARAMETER V7KPassword
		The password of the account connecting to the V7000
	
	.PARAMETER KeyFile
		The SSH public  key of the account.  Must be in OpenSSH format
	
	.PARAMETER RetryTime
		The number of seconds in between retries.  Default is 10 seconds
	
	.PARAMETER Retries
		The Number of retries to attemp.  Default is 6
	
	.PARAMETER LogFile
        The name of the Log file to output infomation to be written to for troubleshooting.
		The default location is the NetWorker logs directory and will be called V7KSnapshot.log.
		If this does not exist it will be put in %systemroot%\temp
        
	.EXAMPLE
		Remove-BackupSnapshot -$V7000Host v7000-1 -V7KUserName superuser -V7KPassword Password1 -KeyFile C:\temp\key.ppk
			-Path C:\Windows\Temp\Vol.csv
	.NOTES
        The Keyfile has to be in OpenSSH format

	
  #>
    [CmdletBinding()]
    Param (
        [string]$LogFile,
        [Parameter()]
        [string]$KeyFile,
        [Parameter(Mandatory=$True)]
        [string]$V7KUserName,
		[string]$Path,
		[int]$RetryCount = 30,
		[int]$RetryDelay = 5

         
    )
    if (-not $LogFile)
    {
        $Logfile = (Get-ItemProperty HKLM:\SOFTWARE\Legato\NetWorker).Path + "logs\V7KSnapshot.log"
    }
    $SnapInfo = Import-Csv -Path $Path
    Write-Verbose "Log file is $($LogFile)"
    Write-Verbose "Key File is $($KeyFile)"
    Write-Verbose "Host is $($SnapInfo.V7000Host)"
    Write-Verbose "Username is $($V7KUserName)"
    Write-Verbose "Source volume is $($SnapInfo.SourceVolume)"
    Write-Verbose "Target host is $($SnapInfo.TargetHostID)"
    Write-Verbose "Target volume is $($SnapInfo.TargetVolume)"
	$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $V7KUserName, (new-object System.Security.SecureString)
	$V7000Host | Out-File $LogFile -Append

    #Connects to the V7000, creates the target disk and creates the snapshot 
    Write-Verbose "Connecting to $($SnapInfo.V7000Host)" 
    Connect-V7K -Computername $SnapInfo.V7000Host -Credential $Cred -KeyFile $KeyFile
    Write-Verbose "Setting disk $($SnapInfo.OSDiskID) to offline"
    Get-Disk $SnapInfo.OSDiskID | Set-Disk -IsOffline:$True
    Write-Verbose "Removing host mapping $($SnapInfo.TargetVolume) from hostid $($SnapInfo.TargetHostID)"
	Remove-V7KvDiskHostMap -Hostid $SnapInfo.TargetHostID -Name $SnapInfo.TargetVolume -Confirm:$false
    Write-Verbose "Rescanning host storage"
    Update-HostStorageCache
    Write-Verbose "Stopping Flash copy $($SnapInfo.FlashCopyId)"
	Stop-V7KFCMap -Id $SnapInfo.FlashCopyId
	Write-Verbose "Getting flash copy state"
	$isStopped = Get-V7KFCMap -id $SnapInfo.FlashCopyId
	Write-Verbose "Flash copy state is $($isStopped.Status)"
	while ($isStopped.Status -ne 'Stopped' -and $RetryCount -ne 0)
	{
		Write-Verbose "Flash copy is not stopped. Waiting for $($RetryDelay) seconds. Retry count:$($RetryCount)"
		Start-Sleep -Seconds $RetryDelay
		$RetryCount -= 1
		$isStopped = Get-V7KFCMap -id $SnapInfo.FlashCopyId
	}
	If ($isStopped.Status -eq 'Stopped')
	{
		Write-Verbose "Deleting flash copy $($SnapInfo.FlashCopyId)"
		Remove-V7KFCMap -Id $SnapInfo.FlashCopyId -Force
		Write-Verbose "Removing snapshot volume $($SnapInfo.TargetVolume)"
		Remove-V7KVDisk -Name $SnapInfo.TargetVolume -Confirm:$False
	}
	else
	{
		Write-Error "Flash copy could not be stopped.  Please wait for it to stop and then remove the flash copy and volume manually using 
			Remove-V7KFCmap -force -id $($SnapInfo.FlashCopyId) and then Remove-V7KVDisk -Name $($SnapInfo.TargetVolume) -Confirm:`$False"
	}
	Get-SSHSession | Remove-SSHSession
	
}

function Copy-V7kNodeFiles {
	[CmdletBinding()]
	param
	(
		[Parameter(ValueFromPipeline = $True)]
		[string]$ComputerName = $Global:DefaultV7K.Host
		
	)
	Process
	{
		$SessionId = $Global:DefaultV7K.SessionID
		$cmd = 'lsnodecanister -filtervalue config_node=yes -delim ","'
		Write-Verbose "Command is $($cmd)"
		
		Write-Verbose "Getting Active Node"
		$ActiveNodeRaw = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
		$ActiveNode = ConvertFrom-Csv $ActiveNodeRaw
		Write-Verbose "Active node is Node $($ActiveNode.Id)"
		If ($ActiveNode.Id -eq 1)
		{
			Write-Verbose "Copying Stats from Node 2 to 1"
			$cmd = "cpdumps -prefix /dumps/iostats 2"
			(Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
			Start-Sleep -Seconds 2
		}
		Else
		{
			Write-Verbose "Copying Stats from Node 1 to 2"
			$cmd = "cpdumps -prefix /dumps/iostats 1"
			(Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
			Start-Sleep -Seconds 2
		}
	}
}

function Get-V7KMonFileList {
<#
  	.SYNOPSIS
		Get a list of the existing stats file
	
	.DESCRIPTION
		Gets a list of the exist stats files on a V7000.  A credtial file must exist for this to work.  It connects
        to a V7000 defined in $ComputerName.  It then finds the active node using lsnodecanister and copies the files
        from the non-active node across.  This is then output to a file.  This output is used to find out what files
        have already been downloaded
	
	.EXAMPLE
		Get-V7KStatFile -ComputerName 172.0.0.10 -Filename C:\Temp\StatsFiles.txt
	
    .PARAMETER ComputerName
		IP address or DNS name of the V7000

    .PARAMETER Filename
        The Path and filename of the file to store the list of stat filenames
	
#>
	[CmdletBinding()]
	param
	(
		[Parameter(ValueFromPipeline = $True)]
		[string]$ComputerName = $Global:DefaultV7K.Host
		
	)
	begin
	{
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
	}
	Process
	{
		Write-Verbose "Generating a list of files"
		$cmd = 'lsdumps -prefix /dumps/iostats -delim ","'
		$statfilesraw = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output | ConvertFrom-Csv
		$statfilesraw
	}
}

Function Convert-V7KMonFileList {
<#
  	.SYNOPSIS
		Converts a Stats List to an Object
	
	.DESCRIPTION
		Converts a list of I/O Stat files from a V7000 into and Object.  This is used to easily find the files which have
        not yet been imported.
	
	.EXAMPLE
		$files = Get-V7KMonFileList -ComputerName 172.0.0.10
        Convert-V7KMonFileList -List $files
	
    .PARAMETER List
		A list of stat files from a V7000.  This could be manually create but it is better to get a list from Get-V7KMonFileList
	
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipeline=$true)]
		$FileList
	)
	Process
	{
		Write-Verbose "$($FileList.FileName)"
		$FileList | ForEach-Object {
			If ($_.FileName)
			{
				$Line = $_ -split "_"
				
				$DateString = "$($Line[3].ToString().Substring(4, 2))-$($Line[3].ToString().Substring(2, 2))-$($Line[3].ToString().Substring(0, 2)) $($Line[4].ToString().Substring(0, 2)):$($Line[4].ToString().Substring(2, 2)):$($Line[3].ToString().Substring(4, 2))"
				$Date = Get-Date $DateString
				
				$hash = @{
					Date = $Date
					FileName = $_.FileName
				}
				
				$obj = New-Object -TypeName PSObject -Property $hash
				$obj
			}
		}
	}
}

function Get-V7KNodeStats
{
	param
	(
		[Parameter(ValueFromPipeline = $True)]
		[Alias('host')]
		[string]$ComputerName = $Global:DefaultV7K.Host
	)
	begin
	{
		$SessionId = Get-V7KConnection $ComputerName
		If ($SessionId -eq $null)
		{
			Write-Error "Not connected to $($ComputerName)"
			break
		}
		$cmd = "lsnodecanisterstats -delim ,"
	}
	
	process
	{
		$info = (Invoke-SSHCommand -SessionId $sessionid -Command $cmd).Output
		$Item = ConvertFrom-Csv $info
		$item | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
		$Item | ForEach-Object {
			$_.stat_peak_time -match "(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})" | Out-Null
			$_.stat_peak_time = Get-Date "$($Matches[3])/$($Matches[2])/$($Matches[1]) $($Matches[4]):$($Matches[5]):$($Matches[6])"
			$_.PSObject.TypeNames.Insert(0, ’SVC.Stat’)
		}
	}
	
	end
	{
		return $Item
	}
}

$global:V7KSessions = @{}
$Global:DefaultV7K = ""
$global:KeyFile = ""
$currentFileLocation = Split-Path $MyInvocation.MyCommand.Path
Update-FormatData "$currentFileLocation\V7000.format.ps1xml"
