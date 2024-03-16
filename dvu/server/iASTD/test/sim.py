import os
import random



while True:
   randbit = random.choice([0, 1])
   if randbit == 1:
      os.system("curl -iX GET httpbin.org/get")
   else:
      os.system("curl -iX POST httpbin.org/post")
