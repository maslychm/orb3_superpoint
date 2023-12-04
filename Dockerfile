FROM nvidia/cuda:11.6.2-base-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# # Install dependencies
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
    ca-certificates wget unzip bzip2 cmake git build-essential pkg-config \
    libjpeg-dev libtiff5-dev libpng-dev \
    libtbb-dev libavcodec-dev libavformat-dev libswscale-dev \
    libxvidcore-dev libx264-dev libgtk2.0-dev libatlas-base-dev \
    libeigen3-dev libblas-dev liblapack-dev libglew-dev gfortran \
    python2.7-dev python3-dev python-numpy python3-numpy \
    libboost-all-dev libboost-python-dev libboost-serialization-dev \
    libgl1-mesa-glx libegl1-mesa libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6 \
    libopenmpi-dev \
    libglu1-mesa-dev freeglut3-dev mesa-common-dev libglew-dev \
    ccache curl \
    libssl-dev

# install anaconda from https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh
RUN wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh \
    && bash Anaconda3-2023.09-0-Linux-x86_64.sh -b \
    && rm Anaconda3-2023.09-0-Linux-x86_64.sh

ENV PATH /root/anaconda3/bin:$PATH
RUN conda init

# Create and configure the Conda environment
# RUN conda create --name torchenv python=3.8 -y \
#     && echo "source activate torchenv" > ~/.bashrc \
#     && /root/anaconda3/bin/conda init bash

RUN conda create --name torchenv python=3.8 -y
RUN /root/anaconda3/bin/conda run -n torchenv conda install pyyaml=5.1 numpy mkl=2019.4 mkl-include=2020.0 setuptools cmake cffi typing

# install torchlib
ENV USE_CUDA=0
ENV NO_CUDA=1
ENV USE_MKLDNN=0
ENV USE_MKL=0
# TODO enable MKL and CUDA
RUN git clone --recursive -b v1.0.1 https://github.com/pytorch/pytorch \
    && cd pytorch \
    && mkdir build \
    && cd build \
    && /root/anaconda3/bin/conda run -n torchenv /bin/bash -c "USE_CUDA=0 python ../tools/build_libtorch.py"

# Install OpenCV
RUN mkdir -p /build/opencv && cd /build/opencv
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/refs/heads/3.4.zip \
    && unzip opencv.zip \
    && cd opencv-3.4/ \
    && mkdir build \
    && cd build \
    && cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_CUDA=OFF -D BUILD_TESTS=OFF -D BUILD_PERF_TESTS=OFF .. \
    && make -j   2>&1 | tee -a  make.log \
    && make install 2>&1 | tee -a  make_install.log

# install Pangolin
RUN mkdir -p /build/Pangolin && cd /build/Pangolin
RUN git clone https://github.com/stevenlovegrove/Pangolin \
    && cd Pangolin \
    && git checkout e1c79a678f1b68e4d19852a108201caaf7b31307 \
    && mkdir build \
    && cd build \
    && cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j \
    && make install

RUN git clone https://github.com/maslychm/orb3_superpoint \
    && cd orb3_superpoint \
    && chmod +x build.sh \
    && /root/anaconda3/bin/conda run -n torchenv /bin/bash -c "./build.sh"
