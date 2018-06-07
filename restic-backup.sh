#!/bin/bash
hostname=`hostname`

export B2_ACCOUNT_ID="4bc42f267688"
export B2_ACCOUNT_KEY="00244196b19d8095255129a248f5e2eff1fd383a52"
export RESTIC_REPOSITORY="b2:linode-${hostname}"
export RESTIC_PASSWORD_FILE=".restic"

restic backup /
