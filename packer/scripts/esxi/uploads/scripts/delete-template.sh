#!/bin/sh -eu -o pipefail -o errtrace
#
# use:
#
#    delete-template.sh $DATASTORE_NAME $TEMPLATE_DIRECTORY
#
DATASTORE_NAME=$1
TEMPLATE_DIRECTORY=$2

DATASTORE_PATH="/vmfs/volumes/$DATASTORE_NAME"
BASE_NAME=$( ls "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/" | grep ".nvram" | awk -F '/' '{print $(NF)}' | awk -F '.' '{print $1}' )
TEMPLATE_NAME=$( ls "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/" | grep ".vmx" | awk -F '/' '{print $(NF)}' | awk -F '.' '{print $1}' )

# delete source folder
rm -f "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$BASE_NAME.nvram"
vmkfstools -U "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$BASE_NAME.vmdk"
rm -f "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$TEMPLATE_NAME.vmsd"
rm -f "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$TEMPLATE_NAME.vmx"
rmdir "$DATASTORE_PATH/$TEMPLATE_DIRECTORY"

exit 0
