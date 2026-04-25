DEVICE ?= iPhone 17 Pro
IOS_DEV_SCRIPT := ./scripts/ios-dev.sh

.PHONY: help ios-devices ios-boot ios-build ios-run ios-test ios-logs ios-clean

help:
	@printf "make ios-devices\n"
	@printf "make ios-boot DEVICE=\"iPhone 17 Pro\"\n"
	@printf "make ios-build DEVICE=\"iPhone 17 Pro\"\n"
	@printf "make ios-run DEVICE=\"iPhone 17 Pro\"\n"
	@printf "make ios-test DEVICE=\"iPhone 17 Pro\"\n"
	@printf "make ios-logs DEVICE=\"iPhone 17 Pro\"\n"
	@printf "make ios-clean\n"

ios-devices:
	@$(IOS_DEV_SCRIPT) list-devices

ios-boot:
	@DEVICE="$(DEVICE)" $(IOS_DEV_SCRIPT) boot

ios-build:
	@DEVICE="$(DEVICE)" $(IOS_DEV_SCRIPT) build

ios-run:
	@DEVICE="$(DEVICE)" $(IOS_DEV_SCRIPT) run

ios-test:
	@DEVICE="$(DEVICE)" $(IOS_DEV_SCRIPT) test

ios-logs:
	@DEVICE="$(DEVICE)" $(IOS_DEV_SCRIPT) logs

ios-clean:
	@$(IOS_DEV_SCRIPT) clean
