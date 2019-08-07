#!/bin/sh -eu -o pipefail -o errtrace
#
# use:
#
#    import-template.sh $DATASTORE_NAME $TEMPLATE_DIRECTORY $VM_NAME
#
DATASTORE_NAME=$1
TEMPLATE_DIRECTORY=$2
VM_NAME=$3

DATASTORE_PATH="/vmfs/volumes/$DATASTORE_NAME"
BASE_NAME=$( ls "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/" | grep ".nvram" | awk -F '/' '{print $(NF)}' | awk -F '.' '{print $1}' )
TEMPLATE_NAME=$( ls "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/" | grep ".vmx" | awk -F '/' '{print $(NF)}' | awk -F '.' '{print $1}' )

# create destination folder
mkdir -p "$DATASTORE_PATH/$VM_NAME"

# delete large files in destination folder
if [ -e "$DATASTORE_PATH/$VM_NAME/$BASE_NAME.vmdk" ] ; then
    vmkfstools -U "$DATASTORE_PATH/$VM_NAME/$BASE_NAME.vmdk"
fi

# copy files to destination folder
cp -f "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$BASE_NAME.nvram" "$DATASTORE_PATH/$VM_NAME/$BASE_NAME.nvram"
vmkfstools -i "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$BASE_NAME.vmdk" "$DATASTORE_PATH/$VM_NAME/$BASE_NAME.vmdk" -d thin
cp -f "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$TEMPLATE_NAME.vmsd" "$DATASTORE_PATH/$VM_NAME/$VM_NAME.vmsd"
cp -f "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$TEMPLATE_NAME.vmx" "$DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx"

exit 0
