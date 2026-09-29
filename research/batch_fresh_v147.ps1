$ErrorActionPreference = "Continue"
$root = "C:\Users\Admin\Downloads\Deobfuscator\Deobfuscator\luraphv15 node"
Set-Location $root
$log = "$env:TEMP\batch_fresh.txt"
"" | Out-File $log -Encoding utf8

$dir = Join-Path $root "sample\v14\v14.7"
$outDir = Join-Path $dir "output"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$files = @(
    "647a35ff2d631d40.lua", "6f59f3d9ee0581f9.lua", "5076d781d37fbfa4.lua",
    "9093c8f6eb0a6630.lua", "63266e1cb30ee0b8.lua", "09a6ea8262fd57b6.lua",
    "071ece4a4f154e4a.lua", "1de859810f08cf23.lua", "b54b0e0a1248d091.lua",
    "d66414036cdf9c34.lua", "41b558f16de2f55d.lua", "0db35fb956dbe590.lua"
)

foreach ($name in $files) {
    $f = Join-Path $dir $name
    if (-not (Test-Path $f)) { Add-Content $log "MISS  $name"; continue }
    $dest = Join-Path $outDir ([IO.Path]::GetFileNameWithoutExtension($name) + ".lua")
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $out = & node deob.js $f --timeout 300 --budget 300 --devirt-rounds 2 -o $dest 2>&1 | Out-String
    $sw.Stop()

    $rec = "STATIC"
    if ($out -match "payload-attributed recovery") { $rec = "PAYLOAD" }
    elseif ($out -match "devirtualization failed") { $rec = "FAIL" }
    elseif ($out -match "produced no output") { $rec = "NO-OUT" }
    elseif ($out -match "parse failed") { $rec = "PARSE" }

    $sz = 0
    $kind = "-"
    if (Test-Path $dest) {
        $sz = (Get-Item $dest).Length
        if ($sz -gt 0) {
            $t = Get-Content $dest -Raw
            if ($t -match "luraph_runtime") { $kind = "SCAFFOLD" }
            else {
                $noise = ([regex]::Matches($t, ':Connect\(function')).Count
                $real = ([regex]::Matches($t, 'print\(|warn\(|GetService|Instance\.new|RemoteEvent|loadstring|SetCore|InvokeServer|FireServer')).Count
                if ($real -gt 0 -and $noise -le 2) { $kind = "SOURCE" }
                elseif ($sz -gt 500) { $kind = "CODE" }
                else { $kind = "TINY" }
            }
        }
    }
    Add-Content $log ("{0,4}s  {1,7}b  {2,-8} {3,-9} {4}" -f [int]$sw.Elapsed.TotalSeconds, $sz, $rec, $kind, $name)
}
Add-Content $log "DONE"
