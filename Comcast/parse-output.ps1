Param($lastAmt = 300)
$files = Get-Item C:\pscripts\output\*_output.txt | select -last $lastAmt
$count = 0
write-output "TimeStamp,Upstream1(dBmV),Upstream2(dBmV),Upstream3(dBmV),ModemUpTime(min)"

foreach($file in $files){
    $yyyy = $file.name.SubString(0,4)
    $mon = $file.name.SubString(4,2)
    $dd = $file.name.SubString(6,2)
    $HH = $file.name.SubString(9,2)
    $min = $file.name.SubString(11,2)
    $ss = $file.name.SubString(13,2)
    $output = "$mon/$dd/$yyyy $($HH):$($min):$ss"
    $d = get-content $file | ?{$_ -match "days"}
    if($d) { 
        $upd = $d.SubString(0,$d.indexOf("days")-1)
        $uph = $d.Substring($d.IndexOf("days")+5,$d.IndexOf("h:")-($d.IndexOf("days")+5))
        $upm = $d.Substring($d.IndexOf("h:")+2,$d.IndexOf("m:")-($d.IndexOf("h:")+2))
        $upsec = $d.Substring($d.IndexOf("m:")+2,$d.LastIndexOf("s")-($d.IndexOf("m:")+2))
        $uph = ([int]$upd * 24) + [int]$uph
        $upmin = ([int]$uph * 60) + [int]$upm
        $uptime = "$upmin"
    } else { $uptime = "0" }

    $up1 = get-content $file | ?{$_ -match "Upstream 1"} | ?{$_ -match "dB"}
    if($up1){
        $ups1 = $up1.SubString($up1.IndexOf(":")+2,$up1.IndexOf("dBmV")-$up1.IndexOf(":")-3)
            
        
        $output += ",$ups1"
        
        $up2 = get-content $file | ?{$_ -match "Upstream 2"} | ?{$_ -match "dB"}
        if($up2){
            $ups2 = $up2.SubString($up2.IndexOf(":")+2,$up2.IndexOf("dBmV")-$up2.IndexOf(":")-3)
            $output += ",$ups2"
            
            $up3 = get-content $file | ?{$_ -match "Upstream 3"} | ?{$_ -match "dB"}
            if($up3){
                $ups3 = $up3.SubString($up3.IndexOf(":")+2,$up3.IndexOf("dBmV")-$up3.IndexOf(":")-3)
                $output += ",$ups3,$uptime"
                write-output $output
            } else { write-output "$output,,$uptime" } 
        }
        else { write-output "$output,,,$uptime" }
    } else { write-output "$output,,,,$uptime" }
}