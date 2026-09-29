$ErrorActionPreference = "Continue"
$root = "C:\Users\Admin\Downloads\Deobfuscator\Deobfuscator\luraphv15 node"
Set-Location $root
$log = Join-Path $env:TEMP "batch_v14_light.txt"
"" | Out-File $log -Encoding utf8

foreach ($v in @("v14.7", "v14.8", "v14.9")) {
    $dir = Join-Path $root "sample\v14\$v"
    $outDir = Join-Path $dir "output"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    $files = Get-ChildItem $dir -File |
        Where-Object { ($_.Extension -eq ".lua" -or $_.Extension -eq ".txt") -and $_.Length -lt 500KB } |
        Sort-Object Length | Select-Object -First 10

    Add-Content $log "=== $v : $($files.Count) light files ==="

    foreach ($f in $files) {
        $dest = Join-Path $outDir ($f.BaseName + ".lua")
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $out = & node deob.js $f.FullName --timeout 300 --budget 300 --devirt-rounds 2 -o $dest 2>&1 | Out-String
        $sw.Stop()

        $rec = "STATIC"
        if ($out -match "payload-attributed recovery") { $rec = "PAYLOAD" }
        elseif ($out -match "devirtualization failed") { $rec = "FAIL" }
        elseif ($out -match "produced no output") { $rec = "NO-OUT" }

        $sz = 0
        $kind = "-"
        if (Test-Path $dest) {
            $sz = (Get-Item $dest).Length
            $t = Get-Content $dest -Raw
            if ($t -match "luraph_runtime") { $kind = "SCAFFOLD" }
            elseif ($t -match "^\s*(print|warn)\(") { $kind = "SOURCE" }
            elseif ($sz -gt 200) { $kind = "CODE" }
            else { $kind = "TINY" }
        }

        Add-Content $log ("{0,4}s  {1,7}b  {2,-9} {3,-8} {4}" -f [int]$sw.Elapsed.TotalSeconds, $sz, $rec, $kind, $f.Name)
    }
    Add-Content $log ""
}

Add-Content $log "DONE"
