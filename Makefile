# Названия бинарей
BINS = samplekube

# URL реестра докерных образов
REGISTRY = docker.io/axard

# Версия сборки из последнего тэга
VERSION := $(shell git describe --tags --always --dirty)

# Тэг для контейнеров
TAG := $(shell git describe --tags --always --dirty)

# Папки проекта с исходниками
SRC_DIRS := cmd internal

# Платформы для которых производить сборку
ALL_PLATFORMS := linux/amd64

# Операционная система и архитектура
#   NOTE: получение с помощью утилиты go накладывает необходимость её наличия в системе
OS := $(if $(GOOS),$(GOOS),$(shell go env GOOS))
ARCH := $(if $(GOARCH),$(GOARCH),$(shell go env GOARCH))

GOPATH := $(if $(GOPATH),$(GOPATH),$(shell go env GOPATH))

BASEIMAGE ?= gcr.io/distroless/static

BUILD_IMAGE ?= golang:1.15.5-buster
GOLANGCI_IMAGE ?= golangci/golangci-lint:v1.31.0

BIN_EXTENSION :=

all: # @HELP Сборка бинарей для одной платформы ($OS/$ARCH)
all: build

build-%:
	@$(MAKE) build                        \
	    --no-print-directory              \
	    GOOS=$(firstword $(subst _, ,$*)) \
	    GOARCH=$(lastword $(subst _, ,$*))

container-%:
	@$(MAKE) container                    \
	    --no-print-directory              \
	    GOOS=$(firstword $(subst _, ,$*)) \
	    GOARCH=$(lastword $(subst _, ,$*))

push-%:
	@$(MAKE) push                         \
	    --no-print-directory              \
	    GOOS=$(firstword $(subst _, ,$*)) \
	    GOARCH=$(lastword $(subst _, ,$*))

all-build: # @HELP Собирает бинарники для всех платформ
all-build: $(addprefix build-, $(subst /,_, $(ALL_PLATFORMS)))

all-container: # @HELP Собирает контейнеры для всех платформ
all-container: $(addprefix container-, $(subst /,_, $(ALL_PLATFORMS)))

all-push: # @HELP Отправляет контейнеры для всех платформ в реестр
all-push: $(addprefix push-, $(subst /,_, $(ALL_PLATFORMS)))

# Папки куда будут складываться бинарники
OUTBINS = $(foreach bin,$(BINS),bin/$(OS)_$(ARCH)/$(bin)$(BIN_EXTENSION))

# Сборка
build: $(OUTBINS)

# Папки необходимые для сборки и тестов
BUILD_DIRS := bin/$(OS)_$(ARCH)     \
              .go/bin/$(OS)_$(ARCH) \
              .go/cache

# Это хак позволяющий повзоляющий обойти гошное поведение постоянно изменяющее
# временную метку файла
# Каждый бинарь - это фасад для соответствующего отпечатка
# Создаём прямую связь между бинарём и отпечатком
$(foreach outbin,$(OUTBINS),$(eval  \
    $(outbin): .go/$(outbin).stamp  \
))

$(OUTBINS):
	@true

# Каждый бинарь - это фасад для соответствующего отпечатка
# Создаём обратную связь между бинарём и отпечатком
$(foreach outbin,$(OUTBINS),$(eval $(strip   \
    .go/$(outbin).stamp: OUTBIN = $(outbin)  \
)))

# Запускаем сборку для всех бинарей в папке ./.go и обновляем реальные бинари,
# если надо изменяем бинарник в ./bin
STAMPS = $(foreach outbin,$(OUTBINS),.go/$(outbin).stamp)
.PHONY: $(STAMPS)
$(STAMPS): go-build
	@echo "binary: $(OUTBIN)"
	@if ! cmp -s .go/$(OUTBIN) $(OUTBIN); then  \
	    mv .go/$(OUTBIN) $(OUTBIN);             \
	    date >$@;                               \
	fi

# Настоящие действия по сборке
go-build: $(BUILD_DIRS)
	@echo
	@echo "building for $(OS)/$(ARCH)"
	@docker run                                                 \
	    -i                                                      \
	    --rm                                                    \
	    -u $$(id -u):$$(id -g)                                  \
	    -v $$(pwd):/src                                         \
	    -w /src                                                 \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin                \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin/$(OS)_$(ARCH)  \
	    -v $$(pwd)/.go/cache:/.cache                            \
	    --env HTTP_PROXY=$(HTTP_PROXY)                          \
	    --env HTTPS_PROXY=$(HTTPS_PROXY)                        \
	    $(BUILD_IMAGE)                                          \
	    /bin/sh -c "                                            \
	        ARCH=$(ARCH)                                        \
	        OS=$(OS)                                            \
	        VERSION=$(VERSION)                                  \
	        ./scripts/build.sh                                  \
	    "

# Пример: make shell CMD="-c 'date > datefile'"
shell: # @HELP Запускает командную оболочку внутри контейнера
shell: $(BUILD_DIRS)
	@echo "launching a shell in the containerized build environment"
	@docker run                                                 \
	    -ti                                                     \
	    --rm                                                    \
	    -u $$(id -u):$$(id -g)                                  \
	    -v $$(pwd):/src                                         \
	    -w /src                                                 \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin                \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin/$(OS)_$(ARCH)  \
	    -v $$(pwd)/.go/cache:/.cache                            \
	    --env HTTP_PROXY=$(HTTP_PROXY)                          \
	    --env HTTPS_PROXY=$(HTTPS_PROXY)                        \
	    $(BUILD_IMAGE)                                          \
	    /bin/sh $(CMD)

CONTAINER_DOTFILES = $(foreach bin,$(BINS),.container-$(subst /,_,$(REGISTRY)/$(bin))-$(TAG))

container containers: # @HELP Собирает контейнер(ы) для каждого бинаря ($OS/$ARCH)
container containers: $(CONTAINER_DOTFILES)
	@for bin in $(BINS); do              \
	    echo "container: $(REGISTRY)/$$bin:$(TAG)"; \
	done

# Каждый дотфайл контейнерной цели может ссылаться на бинарь
# Сделано в 2 шага чтобы использовать специфичные для цели переменные
$(foreach bin,$(BINS),$(eval $(strip                                 \
    .container-$(subst /,_,$(REGISTRY)/$(bin))-$(TAG): BIN = $(bin)  \
)))
$(foreach bin,$(BINS),$(eval                                                                   \
    .container-$(subst /,_,$(REGISTRY)/$(bin))-$(TAG): bin/$(OS)_$(ARCH)/$(bin) build/docker/Dockerfile.in  \
))
# Определение цели для всех дотфайлов контейнеров
$(CONTAINER_DOTFILES):
	@sed                                 \
	    -e 's|{ARG_BIN}|$(BINS)|g'       \
	    -e 's|{ARG_ARCH}|$(ARCH)|g'      \
	    -e 's|{ARG_OS}|$(OS)|g'          \
	    -e 's|{ARG_FROM}|$(BASEIMAGE)|g' \
	    build/docker/Dockerfile.in > .dockerfile-$(BIN)-$(OS)_$(ARCH)
	@docker build -t $(REGISTRY)/$(BIN):$(TAG) -f .dockerfile-$(BIN)-$(OS)_$(ARCH) .
	@docker images -q $(REGISTRY)/$(BIN):$(TAG) > $@
	@echo

push: # @HELP Отправить контейнер с архитектурой ($OS/$ARCH) в ранее определённый реестр образов
push: $(CONTAINER_DOTFILES)
	@for bin in $(BINS); do                    \
	    docker push $(REGISTRY)/$$bin:$(TAG);  \
	done

# NOTE: Не работает т.к. нет в системе команд "gcloud" и "manifest-tool"
#       а ещё кажется с Github работать не будет
manifest-list: # @HELP создаёт манифест списка контейнеров для всех платформ
manifest-list: all-push
	@for bin in $(BINS); do                                   \
	    platforms=$$(echo $(ALL_PLATFORMS) | sed 's/ /,/g');  \
	    manifest-tool                                         \
	        --username=oauth2accesstoken                      \
	        --password=$$(gcloud auth print-access-token)     \
	        push from-args                                    \
	        --platforms "$$platforms"                         \
	        --template $(REGISTRY)/$$bin:$(VERSION)__OS_ARCH  \
	        --target $(REGISTRY)/$$bin:$(VERSION);            \
	done

version: # @HELP Выводит версию ПО
version:
	@echo $(VERSION)

test: # @HELP Запускает тесты с помощью скрипта ./scripts/test.sh
test: $(BUILD_DIRS)
	@docker run                                                 \
	    -i                                                      \
	    --rm                                                    \
	    -u $$(id -u):$$(id -g)                                  \
	    -v $$(pwd):/src                                         \
	    -w /src                                                 \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin                \
	    -v $$(pwd)/.go/bin/$(OS)_$(ARCH):/go/bin/$(OS)_$(ARCH)  \
	    -v $$(pwd)/.go/cache:/.cache                            \
	    --env HTTP_PROXY=$(HTTP_PROXY)                          \
	    --env HTTPS_PROXY=$(HTTPS_PROXY)                        \
	    $(BUILD_IMAGE)                                          \
	    /bin/sh -c "                                            \
	        ARCH=$(ARCH)                                        \
	        OS=$(OS)                                            \
	        VERSION=$(VERSION)                                  \
	        ./scripts/test.sh                                   \
	    "

check: # @HELP Проверяет код линтером
check:
	@echo
	@echo "linting golang code"
	@docker run                                                 \
	    --rm                                                    \
	    -v $$(pwd):/app                                         \
	    -w /app                                                 \
	    --env HTTP_PROXY=$(HTTP_PROXY)                          \
	    --env HTTPS_PROXY=$(HTTPS_PROXY)                        \
	    $(GOLANGCI_IMAGE)                                       \
			golangci-lint run                                       \
			--color always

$(BUILD_DIRS):
	@mkdir -p $@

clean: # @HELP Удаляет собранные контейнеры и временные файлы
clean: container-clean bin-clean
	rm -rf tmp.yaml

container-clean:
	rm -rf .container-* .dockerfile-*

bin-clean:
	rm -rf .go bin

tidy:
tidy: # @HELP Удаляет лишние зависимости Go
	go mod tidy

help: # @HELP Выводит эту справку
help:
	@echo "VARIABLES:"
	@echo "  BINS = $(BINS)"
	@echo "  OS = $(OS)"
	@echo "  ARCH = $(ARCH)"
	@echo "  REGISTRY = $(REGISTRY)"
	@echo
	@echo "TARGETS:"
	@grep -E '^.*: *# *@HELP' $(MAKEFILE_LIST)    \
	    | awk '                                   \
	        BEGIN {FS = ": *# *@HELP"};           \
	        { printf "  %-30s %s\n", $$1, $$2 };  \
	    '

minikube: # @HELP Разворачивает в кубере
minikube: push
	for t in $(shell find ./build/kubernetes -type f -name "*.yaml"); do \
		cat $$t | \
			sed -E "s/\{\{(\s*)\.Release(\s*)\}\}/$(VERSION)/g" | \
			sed -E "s/\{\{(\s*)\.ServiceName(\s*)\}\}/$(BINS)/g"; \
			echo ---; \
	done > tmp.yaml
	kubectl apply -f tmp.yaml
