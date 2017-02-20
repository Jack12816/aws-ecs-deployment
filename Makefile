MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
.PHONY: deploy
.SHELLFLAGS: -e

AWS ?= aws
CAT ?= cat
CURL ?= curl
DATE ?= date
ECHO ?= echo
ENV ?= env
ENVSUBST ?= envsubst
EXIT ?= exit
EXPORT ?= export
GREP ?= grep
HEAD ?= head
JQ ?= jq
PRINTF ?= printf
SED ?= sed
SLEEP ?= sleep
SORT ?= sort
TEST ?= test
TR ?= tr
XARGS ?= xargs

JQ := $(JQ) --raw-output --exit-status

DEPLOY_ENV ?= stage
DEPLOY_DATE ?= $(shell $(DATE) +'%s')
AWS_ECR_REPO ?=
REGISTRY ?= $(AWS_ECR_REPO)
IMAGE_NAME ?= shp
IMAGE_REF ?= latest
CANONICAL_NAME := $(IMAGE_NAME)-$(DEPLOY_ENV)
IMAGE_URI := $(REGISTRY)$(CANONICAL_NAME):$(IMAGE_REF)
TASK_DEFINITION_NAME ?= $(CANONICAL_NAME)
CLUSTER_NAME ?= $(CANONICAL_NAME)
SERVICE_NAME ?= $(CANONICAL_NAME)

# These variables will be filled by recipes
TASK_DEFINITION_REVISION := missing-task-definition-revision
ROLLED_OUT_TASK_DEFINITION_REVISION := missing-rolled-out-task-definition-revision

all:
	# Production/Stage Docker Image Deployment
	#
	# deploy         Update AWS task definitions, update the services
	# clean          Clean up old images on the Docker registry

deploy: roll-out-services
	# We are about to roll out
	#
	#               Image version: $(IMAGE_REF)
	#   Task definitions revision: $(TASK_DEFINITION_REVISION)
	#
	@$(MAKE) TASK_DEFINITION_REVISION=$(TASK_DEFINITION_REVISION) \
		wait-for-roll-out

wait-for-roll-out:
	# Waiting for older revisions to disappear
	@for ATTEMPT in {1..60}; do \
		if STALE=$$($(AWS) ecs describe-services \
			--cluster $(CLUSTER_NAME) \
			--services $(SERVICE_NAME) | \
				$(JQ) '.services[0].deployments | .[] | \
					select(.taskDefinition != "$(TASK_DEFINITION_REVISION)") \
					| .id,.taskDefinition'); then \
			$(ECHO) -e "\n# Current stale deployments (Check $${ATTEMPT}/60):"; \
			$(ECHO) "$${STALE}"; \
			$(SLEEP) 5; \
		else \
			$(ECHO) '# Deployment done'; \
			$(EXIT) 0; \
		fi; \
	done; \
	$(ECHO) '# Service update took too long'; \
	$(EXIT) 1

roll-out-services: register-task-definitions
	# Roll out the new task definitions to the services
	# We will roll out revision $(TASK_DEFINITION_REVISION)
	@$(eval ROLLED_OUT_TASK_DEFINITION_REVISION=$(shell \
		$(AWS) ecs update-service \
			--cluster $(CLUSTER_NAME) \
			--service $(SERVICE_NAME) \
			--task-definition $(TASK_DEFINITION_NAME) \
				| $(JQ) '.service.taskDefinition'))
	# Check if the rolled out revision is the expected one
	@$(TEST) -n '$(ROLLED_OUT_TASK_DEFINITION_REVISION)' \
		-a -n '$(TASK_DEFINITION_REVISION)' \
		-a '$(ROLLED_OUT_TASK_DEFINITION_REVISION)' = '$(TASK_DEFINITION_REVISION)' \
		|| ($(PRINTF) 'Revision `%s` (expected) is not equal to `%s`\n' \
			$(ROLLED_OUT_TASK_DEFINITION_REVISION) \
			$(TASK_DEFINITION_REVISION); \
			$(EXIT) 1)
	# Looks good, we roll out the correct revision
	# Stop all running tasks
	@$(AWS) ecs list-tasks --cluster $(CLUSTER_NAME) \
		| $(JQ) '.taskArns[]' | $(XARGS) -rn1 \
		$(AWS) ecs stop-task --cluster $(CLUSTER_NAME) --task \
		| $(JQ) '.task.taskArn' || true

register-task-definitions: task-definitions
	# Register the new task definitions on AWS
	@$(eval TASK_DEFINITION_REVISION=$(shell \
		$(AWS) ecs register-task-definition \
			--family $(TASK_DEFINITION_NAME) \
			--container-definitions \
				"$$($(CAT) ./config/task-definitions.json | $(TR) -d '\n')" \
					| $(JQ) '.taskDefinition.taskDefinitionArn'))
	@$(TEST) -n '$(TASK_DEFINITION_REVISION)' || ( \
		$(ECHO) 'Registration of the new task definitions failed'; $(EXIT) 1)
	# The current task definitions revision is $(TASK_DEFINITION_REVISION)

task-definitions:
	# Generate the new task definitions file
	@$(EXPORT) IMAGE_URI=$(IMAGE_URI); \
	$(EXPORT) CANONICAL_NAME=$(CANONICAL_NAME); \
	$(EXPORT) DEPLOY_ENV=$(DEPLOY_ENV); \
	$(EXPORT) $(DEPLOY_ENV)_DEPLOY_DATE=$(DEPLOY_DATE); \
	$(EXPORT) ENV_VARS=$$($(ENV) | $(SORT) | $(GREP) -i '^$(DEPLOY_ENV)' \
		| $(SED) \
		-e 's/^$(DEPLOY_ENV)_/        {"name": "/gi' \
		-e 's/=/", "value": "/g' \
		-e 's/$$/"},/g' \
		| $(TR) -d '\n' | $(SED) \
		-e 's/,$$//' \
		-e 's/},/},\n/g' \
		-e 's/$$/\n/g'); \
	$(ENVSUBST) < ./config/task-definitions.json.dist \
		> ./config/task-definitions.json

clean:
	# Clean up old images on the Docker registry
	@$(AWS) ecr list-images --repository-name $(CANONICAL_NAME) \
		| $(JQ) '.imageIds[] | select(.imageTag != "$(IMAGE_REF)") | .imageDigest' \
		| $(SED) 's/^/imageDigest=/g' \
		| $(HEAD) -n-1 \
		| $(XARGS) -r $(AWS) ecr batch-delete-image \
			--repository-name $(CANONICAL_NAME) --image-ids \
				| $(JQ) '.imageIds[].imageTag' || true
