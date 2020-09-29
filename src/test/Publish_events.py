from google.cloud import pubsub_v1
import json
import time

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path("elad-playground", "Autofleer_Topic")

f = open("/src/test/test_events.txt", "r")
event = f.readline()
json_file = json.loads(event)

for event_num in range (1, 3):
    for action_id in range (0, 20):
        json_file['Event']['type']['event_version'] = str(event_num)
        json_file['Event']['payload']['fleet_id'] = action_id
        publisher.publish(topic_path, data=str(json_file).encode("utf-8"))

time.sleep(90)