Before beginning `cp .envrc.tpl .envrc`, edit all empty values accordingly (for passwords you can generate automated ones with `pwgen -s 64 1`), and preferably use [direnv](https://direnv.net/)
to reliably and automatically source the project's environment variables.

The rest of the instructions assume you have ansible and packer installed.

## Build base AMI

1. If not done before, `ansible-galaxy install -r requirements.yml`

1. `cd packer`


1. `packer build matrix-base.json`

## Deploy base instance

1. We do this manually using Hetzner web interface

## Set up DNS

e.g. A-records mapping matrix domain to ip of instance, the rest can be CNAME mapping to matrix domain. Remember to whitelist IP of instance for Namecheap API access for example.

## Deploy Traefik with Netdata (Docker-compose from the instance)

1. `ssh ubuntu@<Instance-IP>`

1. `ssh-keygen` - Proceed through with defaults

1. `cat ~/.ssh/id_rsa.pub`

1. [Create a deploy key on this git repo](https://github.com/Wakoma/matrix/settings/keys) with the contents of previous command (do not allow write access)

1. `git clone git@github.com:Wakoma/matrix.git` (git checkout to correct branch)

1. `cd /home/ubuntu/matrix`

1. `cp .envrc.tpl .envrc` and edit values of `.envrc` as appropriate

1. `direnv allow .envrc`

1. `docker-compose config` (optional)

8. `docker-compose up -d`

9. Check `${DOMAIN_TRAEFIK}` in the browser to see if ssl certificates are active. Sometimes it is necessary to `docker restart traefik` depending on timing with regards to DNS propagation. Sometimes rate limits with free tier DNS providers can cause it to take some time before traefik successfully obtains valid SSL certificates.

## Provision instance with Matrix (Ansible from the provisioner)

1. `cd ansible`

2. `mkdir -p matrix-docker-ansible-deploy/inventory/host_vars/${DOMAIN_MATRIX}`

3. `cp hosts.tpl matrix-docker-ansible-deploy/inventory/hosts`

4. `cp host-vars.yml.tpl matrix-docker-ansible-deploy/inventory/host_vars/${DOMAIN_MATRIX}/vars.yml`

5. `sed -i "s/<your-matrix-domain>/${DOMAIN_MATRIX}/g" matrix-docker-ansible-deploy/inventory/hosts`

6. Continue following docs of [matrix-docker-ansible-deploy](https://github.com/spantaleev/matrix-docker-ansible-deploy) repo

In summary:

7. Configure DNS:

   e.g. 

```
        Type: CNAME
        Name ${DOMAIN_ELEMENT}
        Target ${DOMAIN_MATRIX};
```

```
        Type: SRV
        Service: _matrix-identity
        Protocol: TCP
        Priority: 10
        Weight: 0
        Port: 443
        Target: ${DOMAIN_MATRIX}
```

8. `cd matrix-docker-ansible-deploy` 

9. `ansible-playbook -i inventory/hosts setup.yml --tags=setup-all`

10. `ansible-playbook -i inventory/hosts setup.yml --tags=start`

## Register users

11. SSH to server as before
12. Add admin user to Synapse (Space prepended to avoid password staying in bash history), ` sudo /usr/local/bin/matrix-synapse-register-user <user> <password> 1`
13. You can log in at `${DOMAIN_MATRIX}/synapse-admin` with the following entered into form fields: `<user>`, `<password>`, `${DOMAIN_MATRIX}`


## Edit templates and rerun

14. Read about how to [configure playbook for dimension by retrieving an access token](https://github.com/Wakoma/matrix/blob/main/ansible/matrix-docker-ansible-deploy/docs/configuring-playbook-dimension.md#access-token)
15. Make changes to `inventory/host_vars/${DOMAIN_MATRIX}/vars.yml`
    e.g.

      - To configure dimension you need to read and uncomment block starting with line, `## The following block can only be uncommented on a second run`
      - Supply valid values for `matrix_dimension_admins` (e.g. `@<user>:{{ matrix_domain }}` where `<user>` is substituted for user created at step 12.)
      - Create dedicated dimension non-admin user (through the synapse admin portal, `@dimension:${DOMAIN}` is a good name), then fill in appropriate value for `MATRIX_DIMENSION_ACCESS_TOKEN` (see step 14.)
16. Subsequent runs: `ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start`

## Manual steps to follow
 - [Register Jitsi users](https://github.com/Wakoma/matrix/blob/main/ansible/matrix-docker-ansible-deploy/docs/configuring-playbook-jitsi.md#required-if-configuring-jitsi-with-internal-authentication-register-new-users)
   e.g `docker exec matrix-jitsi-prosody prosodyctl --config /config/prosody.cfg.lua register <USERNAME> matrix-jitsi-web <PASSWORD>`

 - Note, it is not possible to configure dimension by config files
   e.g. To set local jitsi server, in Element, go to Manage Integrations → Settings → Widgets → Jitsi Conference Settings and set Jitsi Domain and Jitsi Script URL appropriately.
