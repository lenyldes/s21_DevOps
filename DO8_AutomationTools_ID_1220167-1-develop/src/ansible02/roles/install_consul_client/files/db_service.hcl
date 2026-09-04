service {
    name = "db"
    port = 5432
    connect {
        sidecar_service {}
    }
}
