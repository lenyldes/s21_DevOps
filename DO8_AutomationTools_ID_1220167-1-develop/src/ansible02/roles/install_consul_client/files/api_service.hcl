service {
    name = "hotel-service"
    port = 8082
    connect {
    sidecar_service {
        proxy {
        upstreams = [
            {
                destination_name = "db"
                local_bind_port = 5432
            }
        ]
        }
    }
    }
}
