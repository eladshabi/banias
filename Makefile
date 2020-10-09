# To run this make file you will need to give the next arguments. PROJECT_ID, DATASET_NAME, TOPIC_NAME and SUBSCRIPTION_NAME.
# If you are lazy (like me), you can just set them up in the following lines :-)

PROJECT_ID=elad-playground
DATASET_NAME=elad-playground:AutoFleet_Dataset
TOPIC_NAME=Autofleer_Topic
SUBSCRIPTION_NAME=AutoFleet_Subscription
SCHEMAS_BUCKET=autofleet_schemas
TEMP_BUCKET=autofleet_temp
TEMPLATE_BUCKET=autofleet_template
TEMPLATE_FILE=main-af
DATASET_LOCATION=US
dataflow_region=us-central1


TABLE_NAME=fleet_2
TEMP_FOLDER=tmp
STAGING_FOLDER=pipeline-staging
EVENTS_SUBSCRIPTION_PATH="projects/$(PROJECT_ID)/subscriptions/$(SUBSCRIPTION_NAME)"
ERRORS_TABLE_NAME=error
DATASET=banias

publish_test_file_path = "/Users/eladshabi/IdeaProjects/elad-banias/backend/src/test/Publish_events.py"
pipeline_test_file_path = "/Users/eladshabi/IdeaProjects/elad-banias/backend/src/test/test_e2e.py"


env_setup: _create_buckets _create_topic _create_subscription _create_dataset

install:
	mvn install

build: install
	mvn package

drain:
	./staging_drainer.sh $(dataflow_region) $(PROJECT_ID)

publish_test:
	python3 $(publish_test_file_path)

test_pipeline:
	python3 $(pipeline_test_file_path)

run_local: build
	mvn exec:java -Dexec.mainClass=com.doitintl.banias.BaniasPipeline \
	-Dexec.cleanupDaemonThreads=false \
	-Dexec.args=" \
	--project=$(PROJECT_ID) \
	--tempLocation=gs://$(TEMP_BUCKET)/ \
	--gcpTempLocation=gs://$(TEMP_BUCKET)/$(TEMP_FOLDER) \
	--runner=DirectRunner \
	--defaultWorkerLogLevel=DEBUG \
	--eventsSubscriptionPath=$(EVENTS_SUBSCRIPTION_PATH) \
    --errorsTableName=$(ERRORS_TABLE_NAME) \
    --GCSSchemasBucketName=$(SCHEMAS_BUCKET) \
    --dataset=$(DATASET) \
    --numWorkers=3 \
	"

run: build
	mvn exec:java -Dexec.mainClass=com.doitintl.banias.BaniasPipeline \
	-Dexec.cleanupDaemonThreads=false \
	-Dexec.args=" \
	--project=$(PROJECT_ID) \
	--tempLocation=gs://$(TEMP_BUCKET)/ \
	--gcpTempLocation=gs://$(TEMP_BUCKET)/$(TEMP_FOLDER) \
	--stagingLocation=gs://$(TEMP_BUCKET)/$(STAGING_FOLDER) \
	--runner=DataflowRunner \
	--defaultWorkerLogLevel=DEBUG \
	--eventsSubscriptionPath=$(EVENTS_SUBSCRIPTION_PATH) \
    --errorsTableName=$(ERRORS_TABLE_NAME) \
    --GCSSchemasBucketName=$(SCHEMAS_BUCKET) \
    --dataset=$(DATASET) \
    --numWorkers=3 \
	"

test_e2e: run publish_test drain test_pipeline

create_template: build
	mvn exec:java -Dexec.mainClass=com.doitintl.banias.BaniasPipeline \
	-Dexec.cleanupDaemonThreads=false \
	-Dexec.args=" \
	--jobName="BaniasPipeline" \
	--project=$(PROJECT_ID) \
	--tempLocation=gs://$(TEMP_BUCKET)/

	--gcpTempLocation=gs://$(TEMP_BUCKET)/$(TEMP_FOLDER) \
	--stagingLocation=gs://$(TEMP_BUCKET)/$(STAGING_FOLDER) \
	--templateLocation=gs://$(TEMPLATE_BUCKET)/$(TEMPLATE_FILE) \
	--runner=DataflowRunner \
	--defaultWorkerLogLevel=DEBUG \
	--eventsSubscriptionPath=$(EVENTS_SUBSCRIPTION_PATH) \
    --errorsTableName=$(ERRORS_TABLE_NAME) \
    --GCSSchemasBucketName=$(SCHEMAS_BUCKET) \
    --dataset=$(DATASET) \
    --numWorkers=3 \
	"

### Helpers:

_create_buckets:
	gsutil ls -b gs://$(TEMP_BUCKET) || gsutil mb gs://$(TEMP_BUCKET)
	gsutil ls -b gs://$(SCHEMAS_BUCKET) || gsutil mb gs://$(SCHEMAS_BUCKET)
ifdef TEMPLATE_BUCKET
	gsutil ls -b gs://$(TEMPLATE_BUCKET) || gsutil mb gs://$(TEMPLATE_BUCKET)
endif

_create_dataset:
	bq ls | grep -w $(DATASET) || bq --location=$(DATASET_LOCATION) mk --dataset $(PROJECT_ID):$(DATASET)

_create_topic:
	gcloud pubsub --project $(PROJECT_ID) topics list | grep -w $(TOPIC_NAME) || gcloud pubsub --project $(PROJECT_ID) topics create $(TOPIC_NAME)

_create_subscription:
	gcloud pubsub --project $(PROJECT_ID) subscriptions list | grep -w $(SUBSCRIPTION_NAME) || gcloud pubsub --project $(PROJECT_ID) subscriptions create $(SUBSCRIPTION_NAME) --topic=$(TOPIC_NAME)