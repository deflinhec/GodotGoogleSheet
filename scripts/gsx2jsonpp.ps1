# 1. pull image
docker pull deflinhec/gsx2jsonpp

# 2. cleanup container
docker stop gsx2jsonpp
docker rm gsx2jsonpp

# 3. create container
docker create -it -p 5000:5000 `
-v ${PWD}\..\volume:/workspace `
-e ARGUMENTS="--host=0.0.0.0 --port=5000" `
--name gsx2jsonpp deflinhec/gsx2jsonpp

# 4. restart container
docker restart gsx2jsonpp
