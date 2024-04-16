#!/bin/bash
# Script to run tinytapeout cocotb test framework in a docker container.
#
# Prior to running this script, the docker image should have been
# created with something like:
#  docker build -t tt06 -f ttbuild.docker

# Obtain directory of the software (based on the location of this
# script) and map the local firmware directory to /project .
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
DPARAM="-v ${SRCDIR}:/project -w /project"

# Run the container
docker run -it --rm ${DPARAM} localhost/tt06 /bin/bash -ic 'source /ttsetup/venv/bin/activate ; cd test ; make'
