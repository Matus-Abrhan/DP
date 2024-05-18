FROM ubuntu:24.04

SHELL ["/bin/bash", "-c"] 

RUN apt update \
	&& apt upgrade -y \
	&& apt install -y opam python3-full python3-pip vim

RUN useradd -ms /bin/bash user
USER user
WORKDIR /home/user
COPY server-0.1.0-py3-none-any.whl .
COPY start.sh .

RUN opam init -y \
	&& opam switch create 4.04.0 \
	&& echo 'eval `(opam config env)`' >> ~/.bashrc

RUN python3 -m venv venv \
	&& source venv/bin/activate \
	&& pip install server-0.1.0-py3-none-any.whl
#RUN pip3 install server-0.1.0-py3-none-any.whl --break-system-packages

CMD tail -f /dev/null

# ENTRYPOINT ["venv/bin/python", "-m", "server.run"]
# ENTRYPOINT ["/bin/bash", "start.sh"]
