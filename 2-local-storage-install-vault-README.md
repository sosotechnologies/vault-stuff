## Step 1: Prepare Local Storage Directories on Nodes
```sh
ssh cafanwii@staging-master
sudo mkdir -p /mnt/disks/vol1
sudo mkdir -p /mnt/disks/vol2
sudo mkdir -p /mnt/disks/vol3
sudo chown cafanwii:cafanwii /mnt
sudo chown cafanwii:cafanwii /mnt/
sudo chown cafanwii:cafanwii /mnt/*
sudo chown cafanwii:cafanwii /mnt/disks
sudo chown cafanwii:cafanwii /mnt/disks/
sudo chown cafanwii:cafanwii /mnt/disks/*
sudo chown cafanwii:cafanwii /mnt/disks/vol1
sudo chown cafanwii:cafanwii /mnt/disks/vol1/
sudo chown cafanwii:cafanwii /mnt/disks/vol2
sudo chown cafanwii:cafanwii /mnt/disks/vol2/
sudo chown cafanwii:cafanwii /mnt/disks/vol3
sudo chown cafanwii:cafanwii /mnt/disks/vol3/

# Repeat the above steps for staging-worker-1 and staging-worker-2
```

## Step 2: Create a StorageClass for Local Storage
Create a StorageClass that uses local storage.

```sh
kubectl apply -f 1-storage-class.yaml
```

## Step 3: Create Persistent Volume Manifests
Create Persistent Volumes (PVs) for each directory created on the nodes.

```sh
kubectl apply -f 2-pv.yaml
kubectl get pv
```

## Step 4: insytall vault with the  pv

```sh
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm pull hashicorp/vault --untar=true
kubectl create ns vault

helm -n vault install vault hashicorp/vault --set "injector.enabled=false" --set "server.dataStorage.enabled=true" --set "server.dataStorage.size=10Gi" --set "server.dataStorage.storageClass=local-storage"
```
