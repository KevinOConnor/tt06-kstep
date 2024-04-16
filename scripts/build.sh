#!/bin/bash
# This is a script for building in a docker container.
#
# Prior to running this script, the docker image should have been
# created with something like:
#  docker build -t tt06 -f ttbuild.docker

# Obtain directory of the software (based on the location of this
# script) and map the local firmware directory to /project .
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
DPARAM="-v ${SRCDIR}:/project -w /project"

# Prepare the src directory for building
ln -sf "/ttsetup/tt/" "${SRCDIR}/tt"

# Commands to run in the container
CMD1="bash -ic 'source /ttsetup/venv/bin/activate ; ./tt/tt_tool.py --create-user-config'"
CMD2="cat src/config.tcl src/user_config.tcl > src/auto_combined.tcl"
CMD3="nix-shell --pure /ttsetup/openlane2/shell.nix --command 'openlane src/auto_combined.tcl'"

# Run the container
docker run -it --rm ${DPARAM} localhost/tt06 /bin/bash -ic \
       "${CMD1} ; ${CMD2} ; ${CMD3}"
