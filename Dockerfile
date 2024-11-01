FROM python:3.10-slim

# Set Rust version
ENV RUST_VERSION=1.81.0

# Install necessary libraries
RUN apt update && \
    apt install --no-install-recommends -y software-properties-common dirmngr \
    build-essential wget gfortran liblapack-dev libblas-dev coreutils \
    libharfbuzz-dev libfribidi-dev libcurl4-openssl-dev time curl \
    libfontconfig1-dev libfreetype6-dev libpng-dev libtiff5-dev \
    libjpeg-dev libssl-dev libxml2-dev libxt-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R from CRAN
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN apt update
RUN apt install --no-install-recommends -y r-base

# Install Rust and Cargo
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y --default-toolchain $RUST_VERSION
RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc
ENV PATH="/root/.cargo/bin:${PATH}"

# Install GSL
COPY requirements/gsl-latest /gsl-latest
RUN cd gsl-latest/gsl-2.7.1 && ./configure && make && make install
RUN ldconfig

# Install R dependencies
RUN R -e "install.packages('BiocManager')"
RUN R -e "BiocManager::install(update = TRUE)"
RUN R -e "BiocManager::install('WGCNA')"
RUN R -e "install.packages('reshape2')"
RUN R -e "install.packages('future')"
RUN R -e "install.packages('future.apply')"

# Install Python dependencies
COPY requirements_python.txt /requirements_python.txt
RUN pip install --no-cache-dir -r /requirements_python.txt

# Move the necessary files and folders within the container
COPY ggca-opts /ggca-opts
COPY tools /tools
COPY run_all_by_number_of_combinations.sh /run_all_by_number_of_combinations.sh
COPY run_all_by_size.sh /run_all_by_size.sh
COPY script.sh /script.sh
RUN chmod +x /script.sh

# Create directories for results and datasets
WORKDIR /
RUN mkdir results
RUN mkdir datasets

VOLUME /results
VOLUME /datasets

# Entrypoint
ENTRYPOINT ["/script.sh"]
