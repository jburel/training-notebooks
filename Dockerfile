FROM imagedata/jupyter-docker:0.8.1
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

# create a python2 environment (for OMERO-PY compatibility)
ADD docker/environment-python2-omero.yml .setup/
RUN conda env update -n python2 -f .setup/environment-python2-omero.yml
# Don't use this:
# /opt/conda/envs/python2/bin/python -m ipykernel install --user --name python2 --display-name 'OMERO Python 2'
# because it doesn't activate conda environment variables
ADD docker/logo-32x32.png docker/logo-64x64.png .local/share/jupyter/kernels/python2/
ADD docker/python2-kernel.json .local/share/jupyter/kernels/python2/kernel.json
USER root
RUN fix-permissions .local
USER $NB_UID

# Cell Profiler (add to the Python2 environment)
ADD docker/environment-python2-cellprofiler.yml .setup/
RUN conda env update -n python2 -f .setup/environment-python2-cellprofiler.yml
# CellProfiler has to be installed in a separate step because it requires
# the JAVA_HOME environment variable set in the updated environment
ARG CELLPROFILER_VERSION=v3.1.3
RUN bash -c "source activate python2 && pip install git+https://github.com/CellProfiler/CellProfiler.git@$CELLPROFILER_VERSION"

# R-kernel and R-OMERO prerequisites
ADD docker/environment-r-omero.yml .setup/
RUN conda env update -n r-omero -f .setup/environment-r-omero.yml && \
    /opt/conda/envs/r-omero/bin/Rscript -e "IRkernel::installspec(displayname='OMERO R')"

USER root
RUN mkdir /opt/romero /opt/omero && \
    fix-permissions /opt/romero /opt/omero
# R requires these two packages at runtime
RUN apt-get install -y \
    libxrender1 \
    libsm6
USER $NB_UID

# install rOMERO
ENV _JAVA_OPTIONS="-Xss2560k -Xmx2g"
ARG ROMERO_VERSION=v0.4.1
RUN cd /opt/romero && \
    curl https://raw.githubusercontent.com/ome/rOMERO-gateway/$ROMERO_VERSION/install.R --output install.R && \
    bash -c "source activate r-omero && Rscript install.R --version=$ROMERO_VERSION"

ARG OMERO_SERVER=OMERO.server-5.4.6-ice36-b87
RUN mkdir /opt/omero && \
    cd /opt/omero && \
    wget -q http://downloads.openmicroscopy.org/omero/5.4.6/artifacts/${OMERO_SERVER}.zip && \
    unzip -q ${OMERO_SERVER}.zip && \
    rm ${OMERO_SERVER}.zip && \
    ln -s ${OMERO_SERVER} OMERO.server && \
    echo '#!/bin/sh\nexec /opt/conda/envs/python2/bin/python /opt/omero/OMERO.server/bin/omero "$@"' > /usr/local/bin/omero && \
    chmod 755 /usr/local/bin/omero

# Clone the source git repo into notebooks
# 20180418: COPY --chown doesn't work on Docker Hub
#COPY --chown=1000:100 . notebooks
COPY . notebooks
RUN chown -R 1000:100 notebooks
USER jovyan
