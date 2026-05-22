PROJECT_ID=szkolenie-docker-01
PROJECT_NUMBER=1032872409074
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Domyślne konto serwisowe Compute (używane przez Cloud Build przy `run deploy --source`)
# na świeżym projekcie nie ma ról IAM — przez co build nie odczyta źródła z bucketu (błąd 403).
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${COMPUTE_SA}" \
    --role="roles/editor" \
    --condition=None
