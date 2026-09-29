$ErrorActionPreference = "Continue"
$root = "C:\Users\Admin\Downloads\Deobfuscator\Deobfuscator\luraphv15 node"
Set-Location $root
$log = "$env:TEMP\batch_fresh3.txt"
"" | Out-File $log -Encoding utf8

# pre-check: is the sample even valid Luau (source repo has corrupt files)?
function Test-Parse($path) {
    $null = & "$root\bin\luau-ast.exe" $path 2>&1
    return ($LASTEXITCODE -eq 0)
}

$files = @(
    "d96dbdc23d53463f.lua", "acb2a3fc19142f7f.lua", "d1d6af35eedefc4c.lua",
    "5429a33f29f45f79.lua", "4c5295c1ac613f31.lua", "4f023b3394ef4416.lua",
    "2d67b51f9df64260.lua", "91e013c6335bd77e.lua", "47c3c5afcc9c4716.lua",
    "bf4c909541c8f90e.lua", "a128c34a422a2871.lua"
)

$ok = 0; $corrupt = 0; $real = 0; $trace = 0
foreach ($name in $files) {
    $f = Join-Path $root "sample\v14\v14.7\$name"
    if (-not (Test-Path $f)) { Add-Content $log "MISS  $name"; continue }

    if (-not (Test-Parse $f)) {
        # corrupt in the source repo: retry the download once
        $ProgressPreference='SilentlyContinue'
        $tmp = "$env:TEMP\rd_$name"
        try {
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/terrorlua/obfuscator-samples/main/Luraph/v14.7/$name" -OutFile $tmp -Headers @{ 'User-Agent'='ps' }
            if ((Get-FileHash $tmp -Algorithm MD5).Hash -ne (Get-FileHash $f -Algorithm MD5).Hash) {
                Copy-Item $tmp $f -Force
            }
        } catch {}
        if (-not (Test-Parse $f)) {
            Add-Content $log ("CORRUPT(in-source-repo)  $name")
            $corrupt++
            continue
        }
    }

    $dest = Join-Path $root "sample\v14\v14.7\output\$([IO.Path]::GetFileNameWithoutExtension($name)).lua"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $out = & node deob.js $f --timeout 300 --budget 300 --devirt-rounds 2 -o $dest 2>&1 | Out-String
    $sw.Stop()

    $rec = "STATIC"
    if ($out -match "payload-attributed recovery") { $rec = "PAYLOAD" }
    elseif ($out -match "devirtualization failed") { $rec = "FAIL" }
    elseif ($out -match "produced no output") { $rec = "NO-OUT" }

    $sz = 0; $kind = "-"
    if (Test-Path $dest) {
        $sz = (Get-Item $dest).Length
        if ($sz -gt 0) {
            $t = Get-Content $dest -Raw
            if ($t -match "luraph_runtime") { $kind = "SCAFFOLD" }
            else {
                $noise = ([regex]::Matches($t, ':Connect\(function')).Count
                $real = ([regex]::Matches($t, 'print\(|warn\(|GetService|Instance\.new|RemoteEvent|loadstring|SetCore|InvokeServer|FireServer|getgenv|request\(')).Count
                if ($real -gt 0 -and $noise -le 2) { $kind = "SOURCE"; $real++ }
                elseif ($sz -gt 500) { $kind = "CODE" }
                else { $kind = "TINY" }
            }
        }
    }
    if ($kind -eq "SOURCE") { $ok++; $real2 = $true } else { $real2 = $false }
    if ($sz -gt 0) { $trace++ }
    Add-Content $log ("{0,4}s  {1,7}b  {2,-8} {3,-9} {4}" -f [int]$sw.Elapsed.TotalSeconds, $sz, $rec, $kind, $name)
}
Add-Content $log ""
Add-Content $log "SUMMARY: $ok real-source / $($files.Count) attempted; $corrupt corrupt-in-source-repo; $(( $files.Count - $ok - $corrupt )) failed/trace"
Add-Content $log "DONE"
