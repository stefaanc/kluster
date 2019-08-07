#!/bin/sh -eu -o pipefail -o errtrace
#
# use:
#
#    export-template.sh $DATASTORE_NAME $VM_NAME $TEMPLATE_DIRECTORY
#            ]
#        }
#    ]
#
DATASTORE_NAME=$1
VM_NAME=$2
TEMPLATE_DIRECTORY=$3

DATASTORE_PATH="/vmfs/volumes/$DATASTORE_NAME"
BASE_NAME=$( ls "$DATASTORE_PATH/$VM_NAME/" | grep ".nvram" | awk -F '/' '{print $(NF)}' | awk -F '.' '{print $1}' )
TEMPLATE_NAME="$( echo $TEMPLATE_DIRECTORY | awk -F '/' '{print $(NF)}' )-vmw"

# create destination folder
mkdir -p "$DATASTORE_PATH/$TEMPLATE_DIRECTORY"

# delete large files in destination folder
if [ -e "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$BASE_NAME.vmdk" ] ; then
    vmkfstools -U "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$BASE_NAME.vmdk"
fi

# copy files to destination folder
cp -f "$DATASTORE_PATH/$VM_NAME/$BASE_NAME.nvram" "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$BASE_NAME.nvram"
vmkfstools -i "$DATASTORE_PATH/$VM_NAME/$BASE_NAME.vmdk" "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$BASE_NAME.vmdk" -d thin
cp -f "$DATASTORE_PATH/$VM_NAME/$VM_NAME.vmsd" "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$TEMPLATE_NAME.vmsd"
cp -f "$DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx" "$DATASTORE_PATH/$TEMPLATE_DIRECTORY/$TEMPLATE_NAME.vmx"

exit 0
