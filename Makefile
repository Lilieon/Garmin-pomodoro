DEVICE ?= fr955
-include properties.local.mk

SDK ?= $(firstword $(wildcard $(HOME)/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-*) $(CIQ_SDK) /opt/connectiq)

KEY ?= $(HOME)/.connectiq/developer_key.der
JUNGLE ?= watch/monkey.jungle
OUT := bin/$(DEVICE).prg

MKBIN := java -jar $(SDK)/bin/monkeybrains.jar

.PHONY: build sim clean key

build: $(OUT)

$(OUT): $(shell find watch -type f 2>/dev/null)
	@mkdir -p bin
	$(MKBIN) -o $@ -f $(JUNGLE) -y $(KEY) -d $(DEVICE) -w

sim: build
	$(SDK)/bin/connectiq &
	$(SDK)/bin/monkeydo $(OUT) $(DEVICE)
clean:
	rm -rf bin

key:
	@mkdir -p $(HOME)/.connectiq
	openssl genrsa -out $(HOME)/.connectiq/developer_key.pem 2048
	openssl pkcs8 -topk8 -inform PEM -outform DER -in $(HOME)/.connectiq/developer_key.pem -out $(KEY) -nocrypt
	@echo "Developer key at $(KEY)"
