docker build --no-cache -t pcython -f cython.Dockerfile .
docker build --no-cache -t pnumba -f numba.Dockerfile .
docker build --no-cache -t porg -f org.Dockerfile .