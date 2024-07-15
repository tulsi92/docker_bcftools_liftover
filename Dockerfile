FROM debian:buster-slim
ARG hver=1.20 # HTSLIB and BCFTOOLS version

# Install dependencies
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y make wget unzip git g++ zlib1g-dev bwa samtools libncurses5-dev \
  libgdiplus libicu-dev libbz2-dev libssl-dev liblzma-dev libcurl4-openssl-dev \
  autoconf libdeflate-dev

# Download and build htslib
RUN wget https://github.com/samtools/htslib/releases/download/$hver/htslib-$hver.tar.bz2 && \
  mkdir htslib && \
  tar -xf htslib-$hver.tar.bz2 -C htslib --strip-components=1 && \
  cd htslib && \
  autoreconf -i && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf htslib-$hver.tar.bz2

# Download and build bcftools
RUN wget https://github.com/samtools/bcftools/archive/refs/tags/$hver.tar.gz && \
  mkdir bcftools && \
  tar -xf $hver.tar.gz -C bcftools --strip-components=1 && \
  cd bcftools && \
  autoreconf -i && \
  ./configure && \
  make && \
  make install && \
  cd .. && rm -rf bcftools $hver.tar.gz

# Compile bcftools plugins
# RUN apt-get install -y libcurl4 libopenblas0-openmp libcholmod4 libsuitesparse-dev
# if [ ! -f /usr/include/cholmod.h ]; then
#   sed 's/^#include "cholmod_/#include "suitesparse\/cholmod_/;s/^#include "SuiteSparse_/#include "suitesparse\/SuiteSparse_/' \
#     /usr/include/suitesparse/cholmod.h | sudo tee /usr/include/cholmod.h

RUN wget -P plugins https://raw.githubusercontent.com/freeseek/score/master/{score.{c,h},{munge,liftover,metal,blup}.c,pgs.{c,mk}} && \
  make && \
  /bin/cp bcftools plugins/{munge,liftover,score,metal,pgs,blup}.so $HOME/bin/

# Clone and install the liftover plugin
# RUN git clone https://github.com/freeseek/score.git && \
#   cd score && \
#   make && \
#   cp *.so $BCFTOOLS_PLUGINS && \
#   cd .. && \
#   rm -rf score

ENTRYPOINT ["bcftools"]

# Set environment variables for plugins
ENV BCFTOOLS_PLUGINS=/bcftools/plugins
ENV PATH="/bcftools:${PATH}"
