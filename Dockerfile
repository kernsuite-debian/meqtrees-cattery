FROM kernsuite/base:4
RUN docker-apt-install \
    casacore-dev \
    casacore-tools \
    casarest \
    python-pip \
    python-pyfits \
    python-numpy \
    python-scipy \
    python-astlib \
    python-casacore \
    libqdbm-dev
RUN docker-apt-install \
    build-essential \
    cmake \
    libblitz0-dev
RUN docker-apt-install \
    binutils-dev

################################
# install latest masters
################################
RUN echo "deb-src http://ppa.launchpad.net/kernsuite/kern-4/ubuntu bionic main" > /etc/apt/sources.list.d/kernsuite-ubuntu-kern-4-bionic.list
RUN apt-get update
RUN apt-get update
RUN apt-get build-dep -y meqtrees-timba meqtrees-cattery
RUN docker-apt-install python-qt4 python-qwt5-qt4 git
RUN mkdir -p /opt/src/meqtrees
ENV BUILD /opt/src/meqtrees
WORKDIR $BUILD

# screw LOFAR makems, build ska-sa makems from source
RUN git clone https://github.com/ska-sa/makems
RUN mkdir -p $BUILD/makems/LOFAR/build/gnu_opt
WORKDIR $BUILD/makems/LOFAR/build/gnu_opt
RUN cmake -DCMAKE_MODULE_PATH:PATH=$BUILD/makems/LOFAR/CMake \
-DUSE_LOG4CPLUS=OFF -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release ../..
RUN make -j 16
RUN make install
ENV PATH=/opt/src/meqtrees/makems/LOFAR/build/gnu_opt/CEP/MS/src:${PATH}

# now the rest of Meqtrees
WORKDIR $BUILD
RUN git clone https://github.com/ska-sa/meqtrees-timba
RUN git clone https://github.com/ska-sa/kittens 
RUN git clone https://github.com/ska-sa/purr
RUN git clone https://github.com/ska-sa/pyxis 
RUN git clone https://github.com/ska-sa/tigger 
ADD . /opt/src/meqtrees/cattery 
RUN git clone https://github.com/ska-sa/owlcat 

#Build Timba

RUN mkdir meqtrees-timba/build
WORKDIR $BUILD/meqtrees-timba
RUN Tools/Build/bootstrap_cmake release
WORKDIR $BUILD
RUN cd meqtrees-timba/build/release && make -j16 && make install

#Install python2.7
# monkeypatch in last compatible astropy
RUN pip install astropy==2.0.11
RUN cd kittens && python2.7 setup.py install
RUN cd purr && python2.7 setup.py install
RUN cd pyxis && python2.7 setup.py install
RUN cd tigger && python2.7 setup.py install
RUN cd cattery && python2.7 setup.py install
RUN cd owlcat && python2.7 setup.py install

ENV LD_LIBRARY_PATH /usr/local/lib:$LD_LIBRARY_PATH
ENV PATH /usr/local/bin:$PATH
RUN ldconfig # update the linker config
################################
# add test
################################
ADD . /code
WORKDIR /code/test/Batchtest

CMD echo '##################################################' && \
    echo 'Starting Python 2.7 testing...' && \
    echo '##################################################' && \
    python2.7 batch_test.py