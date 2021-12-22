[matrix_servers]
matrix.<your-domain> ansible_host=matrix.<your-domain> ansible_ssh_user=ubuntu become=true become_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
