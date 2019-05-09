#!/usr/bin/env bash

if [[ $# -lt 1 ]]; then
    echo usage: $0 PLAYBOOK [ANSIBLEARGS...]
    exit 1
fi

playbook=$1
shift

[[ -e /opt/configuration/environments/manager ]] >/dev/null 2>&1 || { echo >&2 "Configuration repository not mounted at /opt/configuration"; exit 1; }

cd /opt/configuration/environments/manager

[[ -e playbook-$playbook.yml ]] >/dev/null 2>&1 || { echo >&2 "playbook-$playbook.yml is not a playbook"; exit 1; }

command -v ansible-playbook >/dev/null 2>&1 || { echo >&2 "ansible-playbook not installed"; exit 1; }
command -v ansible-galaxy >/dev/null 2>&1 || { echo >&2 "ansible-galaxy not installed"; exit 1; }

ANSIBLE_USER=${ANSIBLE_USER:-dragon}

if [[ ! -e /ansible/secrets/id_rsa.operator ]]; then

    ansible-playbook \
        -i localhost, \
        -e keypair_dest=/ansible/secrets/id_rsa.operator \
        -e @../secrets.yml \
        playbook-keypair.yml

fi

ANSIBLE_ROLES_PATH=/ansible/roles ansible-playbook \
    --private-key /ansible/secrets/id_rsa.operator \
    -i hosts \
    -e @../images.yml \
    -e @../configuration.yml \
    -e @../secrets.yml \
    -e @images.yml \
    -e @configuration.yml \
    -u $ANSIBLE_USER \
    playbook-$playbook.yml "$@"
