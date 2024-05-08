
path "soso-transit/encrypt/sosocrypto" {
    capabilities = ["update"]
}

path "soso-transit/decrypt/sosocrypto" {
    capabilities = ["update"]
}

path "soso-transit/*" {
    capabilities = ["list"]
}


