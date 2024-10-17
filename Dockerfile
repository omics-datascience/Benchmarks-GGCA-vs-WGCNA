FROM python:3.10-slim

COPY . /

RUN apt update && \
    apt install --no-install-recommends -y software-properties-common dirmngr \
    build-essential wget gfortran liblapack-dev libblas-dev coreutils \
    libharfbuzz-dev libfribidi-dev libcurl4-openssl-dev \
    libfontconfig1-dev libfreetype6-dev libpng-dev \
    libtiff5-dev libjpeg-dev

# Instalar R 4.4.2 desde CRAN
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN apt update
RUN apt install --no-install-recommends -y r-base

# Instalar dependencias 
WORKDIR /requirements
# Instalar dependencias de Python 
RUN pip install --no-cache-dir -r requirements_python.txt
# Instalar dependencias de R desde un archivo install.R
RUN Rscript requirements_r.r
# Instalar GSL
RUN cd gsl-latest/gsl-2.7.1 && ./configure && make && make install

WORKDIR /

# Comando de inicio
CMD ["cat", "Readme.md"]
