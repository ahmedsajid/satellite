#!/bin/bash
# This script automatically publishes and promotes content views in Satellite 6
#
# Please make sure that you have supplied username & password in /etc/hammer/cli.modules.d/foreman.yml
# Also disable the timeout by changing request_timeout to -1
# The file should look similar to the following
#:foreman:
#  :enable_module: true
#  :host: 'https://localhost/'
#  :username: 'syncuser'
#  :password: 'syncuser'
#  :request_timeout: -1
# 
# If there are any pending or pause task, please make sure that they have been completed before running this script

# Setting new line as field separator
IFS=$'\n'

# Organization name
ORG="AUS"
# Content View to exclude
EXCLUDE="Puppet"

# List of content view IDs
for CVID in `hammer --output csv content-view list --organization ${ORG} | tail -n+3 | grep -i -v ${EXCLUDE} | cut -d "," -f1`
do
	# echo the command and publish the new version
        echo "hammer content-view publish --id ${CVID}"
        hammer content-view publish --id ${CVID}

        RETVAL=$?

	# If Return value is not 0, then exit from the script
        if [ ${RETVAL} -ne 0 ];then
                echo "exiting due to return code being ${RETVAL}"
                exit ${RETVAL}
        fi

	# sleep to give chance for locks to get cleared up
        sleep 90
done

# sleep to give chance for locks to get cleared up
sleep 90

# List Content view names
for CVNAME in `hammer --output csv content-view list --organization ${ORG} | cut -d "," -f2 | tail -n+3 | grep -i -v ${EXCLUDE}`
do
	# Highest version of the Content View
	HIGHEST_VERSION=`hammer --output csv content-view version list --organization ${ORG} | grep "${CVNAME}" | cut -d "," -f3 | sort -k1,1n | cut -d '.' -f1 | tail -n 1`

        # Get list of Lifecycle environment names
        for LIFECYCLE_ENVIRONMENT in `hammer --output csv lifecycle-environment list --organization ${ORG}  | tail -n+2  | sort -k1,1n | tail -n+2 | cut -d "," -f2`
        do
		# echo the command and promote the lifecycle environment to a particular version of content view version
                echo "hammer content-view version promote --organization ${ORG} --content-view=\"${CVNAME}\" --to-lifecycle-environment=\"${LIFECYCLE_ENVIRONMENT}\" --version ${HIGHEST_VERSION}"
                hammer content-view version promote --organization ${ORG} --content-view="${CVNAME}" --to-lifecycle-environment="${LIFECYCLE_ENVIRONMENT}" --version ${HIGHEST_VERSION}

                RETVAL=$?

		# If Return value is not 0, then exit from the script
                if [ ${RETVAL} -ne 0 ];then
                        echo "exiting due to return code being ${RETVAL}"
                        exit ${RETVAL}
                fi

                # sleep to give chance for locks to get cleared up
                sleep 90
        done
done
