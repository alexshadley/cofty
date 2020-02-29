docker build . -t cofty-api
docker tag cofty-api gcr.io/cofty-268422/cofty-api
docker push gcr.io/cofty-268422/cofty-api

# start stoppig the instance -- takes obscenely long, the container definitely builds faster
gcloud compute instances stop cofty
gcloud compute instances start cofty