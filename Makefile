DEVICE ?= fr955
-include properties.local.mk

SDK ?= $(CIQ_SDK)
ifeq ($(SDK),)
SDK := $(HOME)/connectiq
endif

KEY ?= $(HOME)/.connectiq/developer_key.der
JUNGLE ?= watch/monkey.jungle
OUT := bin/$(DEVICE).prg

MKBIN := java -jar $(SDK)/bin/monkeybrains.jar

.PHONY: build sim clean key

build: $(OUT)

$(OUT):
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
