server = false
datacenter = "dc1"
data_dir   = "/opt/consul"
advertise_addr = "{{ GetInterfaceIP \"eth1\" }}"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
retry_join = ["192.168.56.10"]
ports {
    grpc = 8502
}