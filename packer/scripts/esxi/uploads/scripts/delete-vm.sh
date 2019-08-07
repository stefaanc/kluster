#!/bin/sh -eu -o pipefail -o errtrace
#
# use:
#
#    delete-vm.sh $DATASTORE_NAME $VM_NAME
#
DATASTORE_NAME=$1
VM_NAME=$2

DATASTORE_PATH="/vmfs/volumes/$DATASTORE_NAME"
BASE_NAME=$( ls "$DATASTORE_PATH/$VM_NAME/" | grep ".nvram" | awk -F '/' '{print $(NF)}' | awk -F '.' '{print $1}' )

# delete source folder
vmkfstools -U "$DATASTORE_PATH/$VM_NAME/$BASE_NAME.vmdk"
find "$DATASTORE_PATH/$VM_NAME/" -mindepth 1 | xargs rm -f
rmdir "$DATASTORE_PATH/$VM_NAME"

exit 0
