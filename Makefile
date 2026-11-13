# Usage: make install [MATCH="Yeti"]
MATCH ?= Yeti
LABEL := com.$(USER).yeti-guard
BIN := $(HOME)/.local/bin/yeti-guard
PLIST := $(HOME)/Library/LaunchAgents/$(LABEL).plist
LOG := $(HOME)/Library/Logs/yeti-guard.log

.PHONY: build install uninstall restart logs

build: yeti-guard

yeti-guard: main.swift
	swiftc -O main.swift -o yeti-guard

install: build
	mkdir -p $(dir $(BIN))
	cp yeti-guard $(BIN)
	sed -e 's|@LABEL@|$(LABEL)|g' -e 's|@BIN@|$(BIN)|g' -e 's|@MATCH@|$(MATCH)|g' -e 's|@LOG@|$(LOG)|g' \
		launchagent.plist.in > $(PLIST)
	-launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null
	launchctl bootstrap gui/$$(id -u) $(PLIST)
	@echo "installed; logs: $(LOG)"

uninstall:
	-launchctl bootout gui/$$(id -u)/$(LABEL)
	rm -f $(PLIST) $(BIN)

restart:
	launchctl kickstart -k gui/$$(id -u)/$(LABEL)

logs:
	tail -f $(LOG)
