FROM julia:1.11.3
# add App version info to docker file
# Copy Project.toml first (for better layer caching)
COPY Project.toml .
# Read version from Project.toml and store it
RUN APP_VERSION=$(julia -e 'using TOML; println(TOML.parsefile("Project.toml")["version"])') && \
    echo "export APP_VERSION=$APP_VERSION" >> /etc/environment
# Add version info
LABEL version="${APP_VERSION}" \
      description="GCTB Web App" \
      maintainer="Jan Leppert <jan@janleppert.de>"
# Make version available in container
ENV APP_VERSION=${APP_VERSION}
     
RUN apt-get update && apt-get install -y vim
RUN useradd --create-home --shell /bin/bash genie
RUN mkdir /home/genie/app
COPY . /home/genie/app
WORKDIR /home/genie/app
RUN chown -R genie:genie /home/
USER genie

EXPOSE 8000
EXPOSE 80

ENV JULIA_DEPOT_PATH="/home/genie/.julia"
ENV JULIA_REVISE="off"
ENV GENIE_ENV="prod"
ENV GENIE_HOST="0.0.0.0"
ENV PORT="8000"
ENV WSPORT="8000"
ENV EARLYBIND="true"
ENV JULIA_CPU_TARGET="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)"
#ENV JULIA_DEBUG="all"

RUN julia -e 'using Pkg; \
    Pkg.activate("."); \
    #Pkg.add("Genie"); \
    #Pkg.add("GenieFramework"); \
    #Pkg.add("DataFrames"); \
    #Pkg.add("CSV"); \
    #Pkg.add("GasChromatographySimulator"); \
    #Pkg.add("Stipple"); \
    #Pkg.add("StippleUI"); \
    #Pkg.add("PlotlyBase"); \
    Pkg.instantiate(); \
    Pkg.precompile();'

ENTRYPOINT ["julia", "--project", "-e", "using GenieFramework; Genie.loadapp(); up(async=false);"]
