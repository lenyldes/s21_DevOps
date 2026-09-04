server = true
bootstrap_expect = 1
datacenter = "dc1"
data_dir   = "/opt/consul"
log_level  = "INFO"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
advertise_addr = "{{ GetInterfaceIP \"eth1\" }}"
ui_config {
    enabled = true
}
