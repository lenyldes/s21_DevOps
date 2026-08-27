docker build -t part_4:1.0 .
docker run -d --name part_4 -p 80:81 -v $(pwd)/server/nginx/nginx.conf:/etc/nginx/nginx.conf part_4:1.0