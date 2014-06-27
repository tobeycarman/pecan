#!/bin/bash

FQDN=$( hostname -f )
PSQL="psql -U bety bety -q -t -c"

# function to add a model, takes 6 parameters
# 1 : fully qualified hostname
# 2 : name of the model, shown in web interface
# 3 : type of model (ED2, SIPNET, BIOCRO, dalect, ...)
# 4 : model revision number
# 5 : name of executable, without the path
# 6 : path to the executable
addmodel() {
	HOSTID="(SELECT id FROM machines WHERE hostname='${1}')"
	MODELID="(SELECT id FROM models WHERE model_name='${2}' AND model_type='${3}' AND revision='${4}')"

	# Make sure host exists
	${PSQL} "INSERT INTO machines (hostname, created_at, updated_at)
		SELECT *, now(), now() FROM (SELECT '${1}') AS tmp WHERE NOT EXISTS ${HOSTID};"

	# Make sure model exists
	${PSQL}  "INSERT INTO models (model_name, model_type, revision, created_at, updated_at)
		SELECT *, now(), now() FROM (SELECT '${2}', '${3}', '${4}') AS tmp WHERE NOT EXISTS ${MODELID};"

    # check if binary already added
    COUNT=$( ${PSQL} "SELECT COUNT(id) FROM dbfiles WHERE container_type='Model' AND container_id=${MODELID} AND file_name='${5}' AND file_path='${6}' and machine_id=${HOSTID};" )
    if [ "$COUNT" -gt 0 ]; then
        echo "File ${6}/${5} already added to model ${2} on host ${1}."
        return 0
    fi

	# Add binary
	${PSQL} "INSERT INTO dbfiles (container_type, container_id, file_name, file_path, machine_id) VALUES
		    ('Model', ${MODELID}, '${5}','${6}', ${HOSTID});"

	echo "File ${6}/${5} added to model ${2} on host ${1}."
}

# Add models
addmodel "${FQDN}" "ED2.2" "ED2" "46" "ed2.r46" "/usr/local/bin"
addmodel "${FQDN}" "ED2.2" "ED2" "82" "ed2.r82" "/usr/local/bin"
addmodel "${FQDN}" "SIPNET" "SIPNET" "unk" "sipnet.unk" "/usr/local/bin"
addmodel "${FQDN}" "BioCro" "BIOCRO" "" "true" "/bin"
