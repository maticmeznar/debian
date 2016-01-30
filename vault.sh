#!/bin/bash

TMP_FILE="/dev/shm/vault_data.json.tmp"

vaultCleanup () {
	unset VAULT_APP_ID
	unset VAULT_USER_ID
	unset VAULT_ADDR
	unset VAULT_TOKEN
	rm -f $TMP_FILE
}

vaultLogin () {
	# VAULT_APP_ID="test"
	# VAULT_USER_ID="test-user"
	# export VAULT_ADDR="https://akula:8200"
	declare -gx VAULT_TOKEN=$(curl -fsS "${VAULT_ADDR}"/v1/auth/app-id/login -d '{"app_id":"'${VAULT_APP_ID}'","user_id":"'${VAULT_USER_ID}'"}' | jq -r .auth.client_token)
	if [ $VAULT_TOKEN == "null" ]; then
		echo "vaultLogin: Error. Unable to read or parse from Vault"
		exit 1
	fi
	echo "vaultLogin: Login successful"
}

vaultParse () {
	vault_path=$1
	v_path=$(echo ${vault_path^^} | sed -e s/\\//_/)
	vault read -format=json secret/"$vault_path" > $TMP_FILE
	cat $TMP_FILE
	for key in `jq -r '.data | keys | join(" ")' $TMP_FILE`; do
		keyUpper=${key^^}
		declare -gx "${v_path}_${keyUpper}"=$(jq -r .data.$key $TMP_FILE)
	done
}

# vaultPki () {
# 	vault_path=$1
# 	vault_cn=$2
# 	vault write -format=json pki/issue/"${vault_path}" common_name="${vault_cn}" > $TMP_FILE
# 	declare -gx ${vault_path}_CERT="/dev/shm/"${vault_path}.crt.pem
# 	jq -r .data.certificate $TMP_FILE > ${vault_path}_CERT
# 	declare -gx ${vault_path}_KEY="/dev/shm/"${vault_path}.key.pem
# 	jq -r .data.private_key $TMP_FILE > ${vault_path}_KEY
# }

vaultPki () {
        vault_path=$1
        vault_cn=$2
        vault write -format=json pki/issue/"${vault_path}" common_name="${vault_cn}" > $TMP_FILE
        file_path="/dev/shm/${1}"
        jq -e -r .data.certificate $TMP_FILE > ${file_path}.crt.pem
        jq -e -r .data.private_key $TMP_FILE > ${file_path}.key.pem
}