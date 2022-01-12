# The bare domain name which represents your Matrix identity.
# Matrix user ids for your server will be of the form (`@user:<matrix-domain>`).
#
# Note: this playbook does not touch the server referenced here.
# Installation happens on another server ("matrix.<matrix-domain>").
#
# If you've deployed using the wrong domain, you'll have to run the Uninstalling step, 
# because you can't change the Domain after deployment.
#
# Example value: example.com
matrix_domain: "{{ lookup('env', 'DOMAIN') }}"
matrix_server_fqn_matrix: "{{ lookup('env', 'DOMAIN_MATRIX') }}"
matrix_server_fqn_dimension: "{{ lookup('env', 'DOMAIN_DIMENSION') }}"
matrix_server_fqn_element: "{{ lookup('env', 'DOMAIN_ELEMENT') }}"
matrix_server_fqn_jitsi: "{{ lookup('env', 'DOMAIN_JITSI') }}"

matrix_postgres_connection_password: "{{ lookup('env', 'MATRIX_POSTGRES_CONNECTION_PASSWORD') }}"

matrix_nginx_proxy_base_domain_serving_enabled: true

# Disable generation and retrieval of SSL certs
matrix_ssl_retrieval_method: none

# Configure Nginx to only use plain HTTP
matrix_nginx_proxy_https_enabled: false

# Don't bind any HTTP or federation port to the host
# (Traefik will proxy directly into the containers)
matrix_nginx_proxy_container_http_host_bind_port: ''
matrix_nginx_proxy_container_federation_host_bind_port: ''

# Trust the reverse proxy to send the correct `X-Forwarded-Proto` header as it is handling the SSL connection.
matrix_nginx_proxy_trust_forwarded_proto: true

# Trust and use the other reverse proxy's `X-Forwarded-For` header.
matrix_nginx_proxy_x_forwarded_for: '$proxy_add_x_forwarded_for'

# Disable Coturn because it needs SSL certs
# (Clients can, though exposing IP address, use Matrix.org TURN)
matrix_coturn_enabled: false

# All containers need to be on the same Docker network as Traefik
# (This network should already exist and Traefik should be using this network)
matrix_docker_network: 'traefik'

matrix_nginx_proxy_container_extra_arguments:
  # May be unnecessary depending on Traefik config, but can't hurt
  - '--label "traefik.enable=true"'

  # The Nginx proxy container will receive traffic from these subdomains
  - '--label "traefik.http.routers.matrix-nginx-proxy.rule=Host(`{{ matrix_domain }}`,`{{ matrix_server_fqn_matrix }}`,`{{ matrix_server_fqn_element }}`,`{{ matrix_server_fqn_dimension }}`,`{{ matrix_server_fqn_jitsi }}`)"'
  - '--label "traefik.http.routers.matrix-nginx-proxy.service=matrix-nginx-proxy"'

  # (The 'websecure' entrypoint must bind to port 443 in Traefik config)
  - '--label "traefik.http.routers.matrix-nginx-proxy.entrypoints=websecure"'

  # (The 'dns' certificate resolver must be defined in Traefik config)
  - '--label "traefik.http.routers.matrix-nginx-proxy.tls.certResolver=dns"'

  # The Nginx proxy container uses port 8080 internally
  - '--label "traefik.http.services.matrix-nginx-proxy.loadbalancer.server.port=8080"'

  # The Nginx proxy container will receive traffic from these subdomains
  - '--label "traefik.http.routers.matrix-nginx-proxy-federation.rule=Host(`{{ matrix_domain }}`)"'
  - '--label "traefik.http.routers.matrix-nginx-proxy-federation.service=matrix-nginx-proxy-federation"'

  # (The 'synapse' entrypoint must bind to port 8448 in Traefik config)
  - '--label "traefik.http.routers.matrix-nginx-proxy-federation.entrypoints=synapse"'

  # (The 'dns' certificate resolver must be defined in Traefik config)
  - '--label "traefik.http.routers.matrix-nginx-proxy-federation.tls.certResolver=dns"'

  # The Nginx proxy container uses port 8448 internally for federation
  - '--label "traefik.http.services.matrix-nginx-proxy-federation.loadbalancer.server.port=8448"'

matrix_synapse_container_extra_arguments:
  # May be unnecessary depending on Traefik config, but can't hurt
  - '--label "traefik.enable=true"'

  # The Synapse container will receive traffic from this subdomain
  - '--label "traefik.http.routers.matrix-synapse.rule=Host(`{{ matrix_server_fqn_matrix }}`)"'

  # (The 'synapse' entrypoint must bind to port 8448 in Traefik config)
  - '--label "traefik.http.routers.matrix-synapse.entrypoints=synapse"'

  # (The 'dns' certificate resolver must be defined in Traefik config)
  - '--label "traefik.http.routers.matrix-synapse.tls.certResolver=dns"'

  # The Synapse container uses port 8048 internally
  - '--label "traefik.http.services.matrix-synapse.loadbalancer.server.port=8048"'

# A shared secret (between Coturn and Synapse) used for authentication.
# You can put any string here, but generating a strong one is preferred (e.g. `pwgen -s 64 1`).
matrix_coturn_turn_static_auth_secret: "{{ lookup('env', 'MATRIX_COTURN_TURN_STATIC_AUTH_SECRET') }}"

# A secret used to protect access keys issued by the server.
# You can put any string here, but generating a strong one is preferred (e.g. `pwgen -s 64 1`).
matrix_synapse_macaroon_secret_key: "{{ lookup('env', 'MATRIX_SYNAPSE_MACAROON_SECRET_KEY') }}"

matrix_synapse_admin_enabled: true

# Don't bind any HTTP or federation port to the host
# (Traefik will proxy directly into the containers)
matrix_synapse_admin_container_http_host_bind_port: ""

matrix_synapse_admin_container_extra_arguments:
    # May be unnecessary depending on Traefik config, but can't hurt
    - '--label "traefik.enable=true"'

    # The Synapse Admin container will only receive traffic from this subdomain and path
    - '--label "traefik.http.routers.matrix-synapse-admin.rule=(Host(`{{ matrix_server_fqn_matrix }}`) && Path(`{{matrix_synapse_admin_public_endpoint}}`))"'

    # (Define your entrypoint)
    - '--label "traefik.http.routers.matrix-synapse-admin.entrypoints=websecure"'

    # (The 'dns' certificate resolver must be defined in Traefik config)
    - '--label "traefik.http.routers.matrix-synapse-admin.tls.certResolver=dns"'

    # The Synapse Admin container uses port 80 by default
    - '--label "traefik.http.services.matrix-synapse-admin.loadbalancer.server.port=80"'

matrix_jitsi_enabled: true

# Run `bash inventory/scripts/jitsi-generate-passwords.sh` to generate these passwords,
# or define your own strong passwords manually.
matrix_jitsi_jicofo_component_secret: "{{ lookup('env', 'MATRIX_JITSI_JICOFO_COMPONENT_SECRET') }}"
matrix_jitsi_jicofo_auth_password: "{{ lookup('env', 'MATRIX_JITSI_JICOFO_AUTH_PASSWORD') }}"
matrix_jitsi_jvb_auth_password: "{{ lookup('env', 'MATRIX_JITSI_JVB_AUTH_PASSWORD') }}"
matrix_jitsi_jibri_recorder_password: "{{ lookup('env', 'MATRIX_JITSI_JIBRI_RECORDER_PASSWORD') }}"
matrix_jitsi_jibri_xmpp_password: "{{ lookup('env', 'MATRIX_JITSI_JIBRI_XMPP_PASSWORD') }}"

matrix_jitsi_jvb_container_extra_arguments:
  - "--env DOCKER_HOST_ADDRESS={{ lookup('env', 'DOMAIN_MATRIX') }}"

matrix_jitsi_web_config_resolution_height_ideal_and_max: 1080

## The following block can only be uncommented on a second run because they require services to be running
# matrix_dimension_enabled: true
# 
# matrix_dimension_admins:
#   - "@<user>:{{ matrix_domain }}"
# 
## Remember to create a dimension user account and retrieve its access tokens
# matrix_dimension_access_token: "{{ lookup('env', 'MATRIX_DIMENSION_ACCESS_TOKEN') }}"
# 
## Note, it is not possible to configure dimension by config files
## e.g. To set local jitsi server, in Element, go to Manage Integrations → Settings → Widgets → Jitsi Conference Settings and set Jitsi Domain and Jitsi Script URL appropriately.
