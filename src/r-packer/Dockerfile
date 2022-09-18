FROM condaforge/mambaforge:4.13.0-1

ENV PYTHONDONTWRITEBYTECODE=true

# Setup conda
RUN set -ex && \
    conda config --set always_yes yes --set changeps1 no && \
    conda info -a && \
    conda config --add channels conda-forge && \
    conda install --quiet --freeze-installed -c main conda-pack

ADD packer.sh /packer.sh

ENTRYPOINT [ "/packer.sh" ]
