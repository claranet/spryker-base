#!/bin/sh

# setup_test is a legacy script from the devvm
# some testing code depends on it, so we need to provide the file
# but as we don't want and don't need it, we create a script which
# does nothing


echo "#!/bin/sh" > $WORKDIR/setup_test
chmod +x $WORKDIR/setup_test


