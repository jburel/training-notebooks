FROM imagedata/jupyter-docker:0.8.1
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

USER root
RUN apt-get update
RUN apt-get install -y -q octave unzip
RUN mkdir /opt/octave-omero && \
    fix-permissions /opt/octave-omero 
USER $NB_UID
# Install OMERO
RUN cd /opt/octave-omero && \
    curl https://downloads.openmicroscopy.org/omero/5.4.9/artifacts/OMERO.matlab-5.4.9-ice36-b101.zip -L -o OMERO.matlab.zip && \
    unzip OMERO.matlab.zip

# create a octave-omero environment (for OMERO-PY compatibility)
ADD docker/environment-octave.yml .setup/
RUN conda env update -n octave -q -f .setup/environment-octave.yml
COPY --chown=1000:100 docker/octave-kernel.json .local/share/jupyter/kernels/octave/kernel.json

# Clone the source git repo into notebooks (keep this at the end of the file)
COPY --chown=1000:100 . notebooks
