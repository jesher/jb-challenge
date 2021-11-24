#!/usr/bin/make

SHELL=/bin/bash

PROJECT_DIR=$(shell pwd)

DOCKER_REPO?=jb/infra-challenger
DOCKER_TAG?=latest

build:
	@docker image build --tag ${DOCKER_REPO}:${DOCKER_TAG} \
		-f ./Dockerfile .

init: build
	@docker run -it --rm -v $(PROJECT_DIR):/usr/src \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		${DOCKER_REPO}:${DOCKER_TAG} \
		ash -c "cd infrastructure/eks && terraform init"

plan: init
	@docker run -it --rm -v $(PROJECT_DIR):/usr/src \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		${DOCKER_REPO}:${DOCKER_TAG} \
		ash -c "cd infrastructure/eks && terraform plan"

apply: init
	@docker run -it --rm -v $(PROJECT_DIR):/usr/src \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		${DOCKER_REPO}:${DOCKER_TAG} \
		ash -c "cd infrastructure/eks && terraform apply"

destroy:
	@docker run -it --rm -v $(PROJECT_DIR):/usr/src \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e KUBECONFIG=/usr/src/infrastructure/eks/outputs/kubeconfig \
		${DOCKER_REPO}:${DOCKER_TAG} \
		ash -c "helmfile --file kubernetes/helmfile/helmfile.yaml --log-level=debug --environment dev destroy"

	# https://github.com/hashicorp/terraform-provider-kubernetes/issues/918
	@docker run -it --rm -v $(PROJECT_DIR):/usr/src \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e KUBECONFIG=/usr/src/infrastructure/eks/outputs/kubeconfig \
		${DOCKER_REPO}:${DOCKER_TAG} \
		ash -c "cd infrastructure/eks && terraform refresh && terraform destroy"

grafana:
	URL=$(shell docker run -it --rm -v $(PROJECT_DIR):/usr/src \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e KUBECONFIG=infrastructure/eks/outputs/kubeconfig \
		${DOCKER_REPO}:${DOCKER_TAG} \
		ash -c "kubectl get ingress -n application -ojson | jq -r '.items[].status.loadBalancer.ingress[].hostname'")/grafana
	$(info $(URL))

	@echo "USER=admin"

	PASSWORD=$(shell docker run -it --rm -v $(PROJECT_DIR):/usr/src \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e KUBECONFIG=infrastructure/eks/outputs/kubeconfig \
		${DOCKER_REPO}:${DOCKER_TAG} \
		ash -c "kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo")
	$(info $(PASSWORD))
