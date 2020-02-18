# launches the postgrest container locally

docker run --rm --net=host -p 3000:3000 \
  -e PGRST_DB_URI="postgres://postgres:Taco2019!@34.70.136.195:5432/cofty" \
  -e PGRST_DB_ANON_ROLE="postgres" \
  postgrest/postgrest
