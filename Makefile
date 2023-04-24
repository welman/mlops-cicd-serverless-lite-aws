APP_NAME=mlops-lite-app

DOCKER_IMAGE_TAG=$(APP_NAME):latest
DOCKER_IMAGE_REPO=316650359375.dkr.ecr.ap-southeast-2.amazonaws.com
DOCKER_IMAGE=$(DOCKER_IMAGE_REPO)/$(DOCKER_IMAGE_TAG)
MODEL_S3_URL=s3://welms-models/height-predictor/model.joblib

CF_STACK_NAME=$(APP_NAME)-stack

x:
	echo $(DOCKER_IMAGE)

setup:
	python3.8 -m venv ./.venv
	. .venv/bin/activate

install:
		python3.8 -m pip install --upgrade pip &&\
		python3.8 -m pip --version &&\
		python3.8 -m pip install -r ./src/requirements.txt

package: download-model
	docker build -t $(DOCKER_IMAGE_TAG) .
	docker tag $(DOCKER_IMAGE_TAG) $(DOCKER_IMAGE)

publish: docker-repo-login
	docker push $(DOCKER_IMAGE)

docker-repo-login:
	aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin $(DOCKER_IMAGE_REPO)

download-model:
	aws s3 cp $(MODEL_S3_URL) .

test:
	python -m pytest -vv --cov=cli --cov=mlib --cov=utilscli --cov=app ./tests/test_mlib.py

format:
	black *.py

lint:
	pylint --disable=R,C,W1203,E1101 mlib cli utilscli
	#lint Dockerfile
	#docker run --rm -i hadolint/hadolint < Dockerfile

all: install lint test

deploy-app-runner:
	aws cloudformation create-stack \
		--stack-name $(CF_STACK_NAME) \
		--template-body file://infra/app-runner.yaml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters ParameterKey=AppStackName,ParameterValue=$(CF_STACK_NAME) \
			ParameterKey=AppName,ParameterValue=$(APP_NAME) 

deploy-ecs-fargate:
	#tbd