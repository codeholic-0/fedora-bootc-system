# Create the contaier file - definition 

# build the os oci image

# pull bootc-image-buider image

# Create output dir

# Run : 
    ```Bash
  sudo podman run \                        
  --rm \
  -it \
  --privileged \
  -v "$(pwd)/output:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$(pwd)/config.toml:/config.toml:ro" \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --rootfs ext4 \
  --type anaconda-iso \
  ghcr.io/codeholic-0/zen-bootc:TAG
    ```