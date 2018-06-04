#!/bin/bash

__create_user() {
# Create a user to SSH into as.
useradd admin
SSH_USERPASS=admin
echo -e "$SSH_USERPASS\n$SSH_USERPASS" | (passwd --stdin admin)
echo ssh user password: $SSH_USERPASS
}

# Call all functions
__create_user