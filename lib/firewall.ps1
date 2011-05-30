$FwprofileTypes= @{1="Domain"; 2="Private" ; 4="Public"}
$FwAction      = @{1="Allow"; 0="Block"}
$FwDirection   = @{1="Inbound"; 2="outbound"; "Inbound"=1;"outbound"=2} 
$FwProtocols   = @{1="ICMPv4";2="IGMP";6="TCP";17="UDP";41="IPv6";43="IPv6Route"; 44="IPv6Frag";
                  47="GRE"; 58="ICMPv6";59="IPv6NoNxt";60="IPv6Opts";112="VRRP"; 113="PGM";115="L2TP";
                  "ICMPv4"=1;"IGMP"=2;"TCP"=6;"UDP"=17;"IPv6"=41;"IPv6Route"=43;"IPv6Frag"=44;"GRE"=47;
                  "ICMPv6"=48;"IPv6NoNxt"=59;"IPv6Opts"=60;"VRRP"=112; "PGM"=113;"L2TP"=115}


$fw=New-object -comObject HNetCfg.FwPolicy2
				  
Function Disable-All-Profiles {
	@(1, 2, 4) | %{
		$fw.FireWallEnabled($_) = $false
	}
}

Function Enable-All-Profiles {
	@(1, 2, 4) | %{
		$fw.FireWallEnabled($_) = $true
	}
}

Function Disable-Active-Profile {
	$fw.FireWallEnabled($fw.CurrentProfileTypes) = $false
}

Function Enable-Active-Profile {
	$fw.FireWallEnabled($fw.CurrentProfileTypes) = $true
}

Function Get-EnabledRules {
	$fw.rules | Where-Object {$_.enabled} | Sort-Object -Property direction | `
		Format-Table -Property @{label="Direction"; expression= {$FwDirection[$_.direction]}}, name, `
			@{Label="Action"; expression={$FwAction[$_.action]}}, @{Label="Protocol"; expression= {$FwProtocols[$_.protocol]}},`
			localPorts -Autosize -wrap 
}

Function Get-FirewallConfig {
	"Active Profiles(s) :" + (Convert-fwprofileType $fw.CurrentProfileTypes)

	@(1,2,4) | select `
                  @{Name="Network Type"     ;expression={$FwprofileTypes[$_]}},
                  @{Name="Firewall Enabled" ;expression={$fw.FireWallEnabled($_)}},
                  @{Name="Block All Inbound";expression={$fw.BlockAllInboundTraffic($_)}},
                  @{name="Default In"       ;expression={$FwAction[$fw.DefaultInboundAction($_)]}},
                  @{Name="Default Out"      ;expression={$FwAction[$fw.DefaultOutboundAction($_)]}} `
            | Format-Table -auto
}

Function Convert-FWProfileType($profileCode){
	$descriptions= @()
	$FwprofileTypes.keys | %{
		if ($profileCode -bAND $_) { 
			$descriptions += $FwprofileTypes[$_] 
		} 
	}
    $descriptions
}

