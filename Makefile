DEVICE ?= fr955
-include properties.local.mk

SDK ?= $(firstword $(wildcard $(HOME)/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-*) $(CIQ_SDK) /opt/connectiq)
SIMSDK ?= $(HOME)/ciq841

KEY ?= $(HOME)/.connectiq/developer_key.der
JUNGLE ?= watch/monkey.jungle
OUT := bin/$(DEVICE).prg
SELFTEST_OUT := bin/selftest.prg

MKBIN := java -jar $(SDK)/bin/monkeybrains.jar

.PHONY: build sim selftest clean key

build: $(OUT)

$(OUT): $(shell find watch -type f 2>/dev/null)
	@mkdir -p bin
	$(MKBIN) -o $@ -f $(JUNGLE) -y $(KEY) -d $(DEVICE) -w

bin/selftest.prg: $(shell find watch -type f 2>/dev/null)
	@mkdir -p bin
	$(MKBIN) -o $@ -f watch/selftest.jungle -y $(KEY) -d $(DEVICE) -w

sim: build
	# 9.x sims reject developer-signed PRGs ("signature check failed") — use the 8.4.1 sim
	$(SIMSDK)/bin/connectiq &
	$(SIMSDK)/bin/monkeydo $(OUT) $(DEVICE)

selftest: bin/selftest.prg
	@bash -c 'rm -rf $(HOME)/Sim-node; DISPLAY=:0 $(SIMSDK)/bin/connectiq >/dev/null 2>&1 & pid=$$!; trap "kill $$pid 2>/dev/null; rm -rf $(HOME)/Sim-node" EXIT; for i in $$(seq 60); do (echo > /dev/tcp/127.0.0.1/1234) 2>/dev/null && break; sleep 1; done; sleep 3; timeout 150 $(SIMSDK)/bin/monkeydo $(SELFTEST_OUT) $(DEVICE)'
clean:
	rm -rf bin

key:
	@mkdir -p $(HOME)/.connectiq
	openssl genrsa -out $(HOME)/.connectiq/developer_key.pem 2048
	openssl pkcs8 -topk8 -inform PEM -outform DER -in $(HOME)/.connectiq/developer_key.pem -out $(KEY) -nocrypt
	@echo "Developer key at $(KEY)"
