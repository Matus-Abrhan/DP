#
# SIMPLE BENCHMARKING ANALYSIS
#
import os

num_events=[1, 2, 5, 7, 10, 20, 50, 70, 100, 200, 500, 700, 1000, 2000, 5000, 7000, 10000, 20000, 50000, 70000, 100000, 200000, 500000, 700000, 1000000, 10000000, 100000000]

for n in num_events:
   # run tcpdump to gather sim.py packets
   print("==Starting capture...\n")
   os.system("sudo tcpdump -c "+str(n)+" -i eth0 -w "+str(n)+".pcap")
   os.system("sudo chmod 777 "+str(n)+".pcap")
   print("==Capture ended.\n")

   # starting analysis with Snort
   print("==Starting Snort analysis...\n")
   os.system("sudo snort -r "+str(n)+".pcap -c /etc/snort/snort.conf -l /tmp/so/cmg -A cmg | tee snort-"+str(n)+".log")
   print("==Snort analysis ended.\n")

   # starting analysis with Bro
   print("==Starting Bro analysis...\n")
   os.system("sudo bro -Q -r "+str(n)+".pcap /usr/share/bro/base/frameworks/signatures/main.bro | tee bro-"+str(n)+".log")
   print("==Bro analysis ended.\n")

   # starting analysis with iASTD
   print("==Starting iASTD...\n")
   print("++ Entering path ~/Dropbox/iASTD\n")
   print("++ Starting iASTD analysis\n")
   os.system("cd /home/ubuntu/Dropbox/iASTD && ./iASTD -s bench.spec -pcap /home/ubuntu/"+str(n)+".pcap | tee iastd-"+str(n)+".log")
   print("++ Change dir to ubuntu\n")
   os.system("cd /home/ubuntu")
   print("== xASTD analysis ended.")

