IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
Install-AtomicRedTeam -getAtomics -Force

$i=1
for(;$i -le 10; $i++)
{
	Invoke-AtomicTest T1083-6
	Invoke-AtomicTest T1222.001-2
	Invoke-AtomicTest T1486-8
	Start-Sleep -Seconds 2.0
	Invoke-AtomicTest T1053.005-3
	Invoke-AtomicTest T1056.001-1
	Invoke-AtomicTest T1059.001-1
	Start-Sleep -Seconds 2.0

}
