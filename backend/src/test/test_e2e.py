from google.cloud import bigquery

client = bigquery.Client()
query_job = client.query(
        """
        SELECT count(*) as counted_tables FROM banias.INFORMATION_SCHEMA.TABLES
        where table_name != 'error'"""
    )

results = query_job.result()  # Waits for job to complete.
for row in results:
    if row.counted_tables == 2:
        print("Test completed")
        exit(0)

    else:
        print("ERROR")
        exit(1)