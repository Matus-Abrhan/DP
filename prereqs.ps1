IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
Install-AtomicRedTeam -getAtomics -Force

Invoke-AtomicTest T1083-6 -GetPrereqs
Invoke-AtomicTest T1222.001-2 -GetPrereqs
Invoke-AtomicTest T1486-8 -GetPrereqs
