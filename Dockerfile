FROM ubuntu:20.04

# Use New Zealand mirrors
RUN sed -i 's/archive/nz.archive/' /etc/apt/sources.list

RUN apt update

# Set timezone to Auckland
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y locales tzdata git
RUN locale-gen en_NZ.UTF-8
RUN dpkg-reconfigure locales
RUN echo "Pacific/Auckland" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
ENV LANG en_NZ.UTF-8
ENV LANGUAGE en_NZ:en

# Create user 'kaimahi' to create a home directory
RUN useradd kaimahi
RUN mkdir -p /code
RUN ln -s /code /home/kaimahi
RUN chown -R kaimahi:kaimahi /code
ENV HOME /home/kaimahi

# Install apt packages
RUN apt update
RUN apt install -y awscli curl software-properties-common ffmpeg libsm6 libxext6
RUN add-apt-repository ppa:deadsnakes/ppa

# Install python
ENV PYTHON_VERSION 3.10
RUN apt update
RUN apt install -y python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-distutils
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python${PYTHON_VERSION}

# Install python packages
RUN python${PYTHON_VERSION} -m pip install --upgrade pip
COPY requirements.txt /root/requirements.txt
RUN python${PYTHON_VERSION} -m pip install --ignore-installed PyYAML
RUN python${PYTHON_VERSION} -m pip install -r /root/requirements.txt
RUN python${PYTHON_VERSION} -m pip install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cpu
