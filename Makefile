HOSTNAME=test

.PHONY: watch
watch:
	watchexec -e sh,Dockerfile -- docker build -t arch-aarch64-image-builder .

.PHONY: build
build:
	docker run -it --rm --privileged=true --dns=1.1.1.1 --dns=8.8.8.8 -v "/dev:/dev" -v "$$(pwd):/work" arch-aarch64-image-builder

.PHONY: flash
flash:
	sudo flash --config ./device-init.yaml --hostname $(HOSTNAME) --userdata=userdata.sh -d /dev/sdc arch-aarch64-cloudinit.img