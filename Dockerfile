ARG GPU=1
ARG CUDA_VERSION=10.1

FROM ubuntu:bionic-20200713
RUN apt update && apt install -qq -o=Dpkg::Use-Pty=0 fish -y
RUN apt install wget -y
RUN [ $(getent group 1001) ] || groupadd --gid 1001 1001
RUN useradd --no-log-init --no-create-home -u 1001 -g 1001 --shell /bin/bash esowc
RUN mkdir -m 777 /usr/app /.creds /home/esowc
ENV HOME=/home/esowc
WORKDIR /usr/app
USER 1001:1001
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.3-Linux-x86_64.sh
RUN chmod +x Miniconda3-py37_4.8.3-Linux-x86_64.sh
RUN bash Miniconda3-py37_4.8.3-Linux-x86_64.sh -b -p $HOME/miniconda3
ARG CONDA=${HOME}/miniconda3/bin
RUN ${CONDA}/conda init bash
COPY --chown=1001:1001 environment.yml /usr/app
# RUN ${CONDA}/conda init {bash,fish}
#RUN /opt/conda/bin/conda create --name deepfwi --clone caliban
#RUN /opt/conda/bin/conda init {bash,fish}
#RUN /opt/conda/bin/conda activate caliban

RUN if [ "$GPU" = 1 ]; then \
${CONDA}/conda install cudatoolkit=$CUDA_VERSION -c pytorch; \
fi;
RUN ${CONDA}/conda env update --name base --file environment.yml && \
${CONDA}/conda clean -y -q --all
COPY --chown=1001:1001 . /usr/app/.

RUN echo "Installing Apex"
RUN if [ "$GPU" = 1 ]; then \
pip uninstall -y -qq apex && \
git clone --depth=1 https://github.com/NVIDIA/apex.git && \
cd /usr/app/apex && \
pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" . \
&& rm /usr/app/apex -r; \
fi;

WORKDIR /usr/app
