#!/bin/bash
# This is a script for viewing gds-ii via docker container.
#
# Prior to running this script, the docker image should have been
# created with something like:
#  docker build -t tt06 -f ttbuild.docker

# Map x-windows socket into container
DPARAM="-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=${DISPLAY}"

# Obtain directory of the software (based on the location of this
# script) and map the local firmware directory to /project .
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
DPARAM="${DPARAM} -v ${SRCDIR}:/project -w /project"

# Command to run
CMD='openlane --last-run --flow openinopenroad src/auto_combined.tcl'

# Run the container
docker run -it --rm ${DPARAM} localhost/tt06 /bin/bash -ic "nix-shell /ttsetup/openlane2/shell.nix --command '${CMD}'"
