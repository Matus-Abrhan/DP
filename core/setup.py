from setuptools import setup, find_packages

setup(name='core',
      version='1.0',
      packages=find_packages(include=['server', 'client', 'general']),
      install_requires=[
          'PyYAML',
          'pexpect',
          'pytest',
          'python-evtx',
          'xmltodict',
      ],
      )
