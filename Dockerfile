FROM kernsuite/base:3
RUN docker-apt-install \
    casacore-dev \
    casacore-tools \
    casarest \
    python-pip \
    python-pyfits \
    python-numpy \
    python-scipy \
    python-astlib \
    python-casacore
RUN docker-apt-install \
    build-essential \
    cmake \
    makems

################################
# install latest masters
################################
RUN echo "deb-src http://ppa.launchpad.net/kernsuite/kern-3/ubuntu xenial main" > /etc/apt/sources.list.d/kernsuite-ubuntu-kern-3-xenial.list
RUN apt-get update
RUN apt-get build-dep -y meqtrees-timba meqtrees-cattery
RUN docker-apt-install python-qt4 python-qwt5-qt4 git
RUN mkdir -p /opt/src/meqtrees
ENV BUILD /opt/src/meqtrees
WORKDIR $BUILD
RUN git clone https://github.com/ska-sa/meqtrees-timba
RUN git clone https://github.com/ska-sa/kittens 
RUN git clone https://github.com/ska-sa/purr 
RUN git clone https://github.com/ska-sa/pyxis 
RUN git clone https://github.com/ska-sa/tigger 
RUN git clone https://github.com/ska-sa/meqtrees-cattery 
RUN git clone https://github.com/ska-sa/owlcat 
RUN mkdir meqtrees-timba/build
WORKDIR $BUILD/meqtrees-timba
RUN Tools/Build/bootstrap_cmake release
WORKDIR $BUILD
RUN cd meqtrees-timba/build/release && make -j8 && make install
RUN cd kittens && python setup.py install
RUN cd purr && python setup.py install
RUN cd pyxis && python setup.py install
RUN cd tigger && python setup.py install
RUN cd meqtrees-cattery && python setup.py install
RUN cd owlcat && python setup.py install
ENV LD_LIBRARY_PATH /usr/local/lib:$LD_LIBRARY_PATH
ENV PATH /usr/local/bin:$PATH
RUN ldconfig # update the linker config
################################
# add test
################################
ADD . /code
WORKDIR /code
RUN python setup.py install
WORKDIR /code/test/Batchtest
CMD python batch_test.py
