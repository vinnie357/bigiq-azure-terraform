default: build test

export CONTAINER_IMAGE = 'dev-azure-cli'

dev: build test shell

build:
	docker build -t ${CONTAINER_IMAGE} .

test: test1 test2

shell:
	@docker run --rm -it \
	-e ARM_CLIENT_ID=${ARM_CLIENT_ID} \
	-e ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET} \
	-e ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID} \
	-e ARM_TENANT_ID=${ARM_TENANT_ID} \
	${CONTAINER_IMAGE} \
	bash -c "az login --service-principal --username ${ARM_CLIENT_ID} --password ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID};bash"

test1:
	@echo "test az command"
	@docker run --rm -it ${CONTAINER_IMAGE} \
	az --version
test2:
	@echo "test az login"
	@docker run --rm -it ${CONTAINER_IMAGE} \
	az login --service-principal --username ${ARM_CLIENT_ID} --password ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}