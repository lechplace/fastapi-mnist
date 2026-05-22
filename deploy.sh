gcloud run deploy mnist-api \
    --source . \
    --region europe-west1 \
    --allow-unauthenticated \
    --memory 1Gi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --timeout 60
