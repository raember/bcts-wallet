#!/bin/bash

NVM_VERSION='0.35.3'
NODE_VERSION='9.11.2'
PY_VENV='venv'
NODE_VENV='node-env'
NODEENV='nodeenv'

# Helper functions
msg(){ echo -e "\033[32m ==>\033[m\033[1m $1\033[m" ;}
msg2(){ echo -e "\033[34m   ->\033[m\033[1m $1\033[m" ;}
warning(){ echo -e "\033[33m ==>\033[m\033[1m $1\033[m" >&2 ;}
error(){ echo -e "\033[31m ==>\033[m\033[1m $1\033[m" >&2 ;}
py_venv_in(){
    msg2 "Activating python3 venv"
    if ! . "$PY_VENV/bin/activate"; then
        error "Failed activating python3 venv"
        exit 1
    fi
}
py_venv_out(){
    msg2 "Deactivating python3 venv"
    if ! deactivate; then
        error "Failed deactivating python3 venv"
        exit 1
    fi
}
node_venv_in(){
    msg2 "Activating node venv"
    if ! . "$NODE_VENV/bin/activate"; then
        error "Failed activating node venv"
        exit 1
    fi
}
node_venv_out(){
    msg2 "Deactivating node venv"
    if ! deactivate_node; then
        error "Failed deactivating node venv"
        exit 1
    fi
}


## PREREQUISITES
check_program(){ # name, version-cmd
	msg2 "Checking $1"
	if ! $2 &> /dev/null; then
		error "$1 not installed. Please install manually"
		exit 1
	else
		msg2 "$1 version: $($2)"
	fi
}

check_nvm(){
	msg2 "Checking nvm"
	if [ -z ${NVM_DIR+x} ] && ! command -v nvm &> /dev/null; then
		msg2 "nvm not installed. Installing now ($NVM_VERSION)"
		if ! curl -o- "https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh" | bash; then
			error "Failed installing nvm"
			exit 1
		fi
		export NVM_DIR="$HOME/.nvm"
		[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
		[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
		msg2 "$(nvm --version)"
	else
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
		msg2 "$(nvm --version)"
	fi
}

## Core functions
setup_py_venv(){
	if [ ! -d "$PY_VENV" ]; then
		msg2 "No venv present yet. Creating now"
		if ! python3 -m venv "$PY_VENV"; then
			error "Failed creating python venv"
			exit 1
		else
			msg2 "Created python venv"
		fi
	fi
}

check_node_env_exists(){
	if ! command -v nodeenv &> /dev/null; then
		msg2 "Installing node-env via pip3"
        if ! pip3 install -e "git+https://github.com/ekalinin/nodeenv.git#egg=nodeenv"; then
            error "Failed installing node-env pip3 package"
            exit 1
        fi
    else
        msg2 "node-env already installed"
	fi
}

setup_node_env(){
    if [[ ! -d "$NODE_VENV" ]]; then
        msg2 "Install specific node version venv ($NODE_VERSION) into $NODE_VENV"
        if ! nodeenv --node="$NODE_VERSION" "$NODE_VENV"; then
            error "Failed setting up venv"
            exit 1
        fi
    else
        msg2 "node-env venv already created"
    fi
}


# Check prerequisites:
msg "Checking prerequisites"
check_program python3 'python3 --version'
check_program pip3 'pip3 -V'
check_program node 'node -v'
check_program npm 'npm -v'
check_nvm

# Set up burner-wallet
msg "Setting up burner wallet"
setup_py_venv

py_venv_in
    check_node_env_exists
    setup_node_env
py_venv_out

msg2 "Change address in clevis.json"
sed -i 's|http://localhost|https://rpc.bluchain.pro|g' clevis.json

msg "Installing packages and setting up server"
node_venv_in
    msg2 "Installing npm packages"
    npm i
    msg2 "Initializing clevis"
    npx clevis init
node_venv_out
